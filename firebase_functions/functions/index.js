const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: Triggered when an order is created or updated in Firestore
 * Sends FCM notification to all staff members
 */
exports.onOrderCreatedOrUpdated = functions.firestore
  .document('orders/{orderId}')
  .onWrite(async (change, context) => {
    try {
      const orderId = context.params.orderId;
      const newData = change.after.data();
      const oldData = change.before.data();

      // If document was deleted, don't send notification
      if (!change.after.exists) {
        console.log(`Order ${orderId} was deleted`);
        return;
      }

      // Determine what happened
      const isNewOrder = !change.before.exists;
      const statusChanged = oldData && oldData.status !== newData.status;

      let title = '';
      let body = '';
      let notificationData = {
        orderId: orderId,
        orderNumber: newData.orderNumber,
        type: 'order_update'
      };

      // Determine notification message based on event type
      if (isNewOrder) {
        title = '🆕 New Order Created';
        body = `Order ${newData.orderNumber} for ${newData.customerName} - ${newData.itemCount} items`;
        notificationData.type = 'new_order';
      } else if (statusChanged) {
        const newStatus = newData.status.toLowerCase();
        const oldStatus = oldData.status.toLowerCase();

        if (newStatus === 'received' && oldStatus === 'notreceived') {
          title = '📥 Order Received';
          body = `Order ${newData.orderNumber} has been received`;
          notificationData.type = 'order_received';
        } else if (newStatus === 'completed') {
          title = '✅ Order Completed';
          body = `Order ${newData.orderNumber} for ${newData.customerName} is now complete!`;
          notificationData.type = 'order_completed';
        } else if (newStatus === 'cancelled') {
          title = '❌ Order Cancelled';
          body = `Order ${newData.orderNumber} has been cancelled`;
          notificationData.type = 'order_cancelled';
        } else {
          // Other status changes
          return console.log(`Status changed from ${oldStatus} to ${newStatus} - no notification needed`);
        }
      } else {
        // Order was updated but status didn't change - no notification needed
        return console.log(`Order ${orderId} was updated but no notification needed`);
      }

      // Get all device tokens from the deviceTokens collection
      const tokensSnapshot = await db.collection('deviceTokens').get();
      
      if (tokensSnapshot.empty) {
        console.log(`No device tokens found for order ${orderId}`);
        return;
      }

      const deviceTokens = [];
      tokensSnapshot.forEach(doc => {
        const token = doc.data().token;
        if (token) {
          deviceTokens.push(token);
        }
      });

      if (deviceTokens.length === 0) {
        return console.log(`No valid device tokens found for order ${orderId}`);
      }

      console.log(`Sending notification to ${deviceTokens.length} devices for order ${orderId}`);

      // Prepare the FCM message
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          orderId: orderId,
          orderNumber: newData.orderNumber,
          type: notificationData.type,
        },
        // Use multicast to send to multiple devices
        tokens: deviceTokens,
      };

      // Send notification to all devices
      const response = await messaging.sendMulticast(message);

      // Log results
      console.log(`Successfully sent notification for order ${orderId}:`);
      console.log(`- Success: ${response.successCount}`);
      console.log(`- Failure: ${response.failureCount}`);

      // Optionally handle failed tokens (remove them from database)
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(deviceTokens[idx]);
          }
        });

        // Remove invalid tokens from database
        if (failedTokens.length > 0) {
          console.log(`Removing ${failedTokens.length} invalid tokens`);
          const batch = db.batch();
          failedTokens.forEach(token => {
            const docRef = db.collection('deviceTokens').doc(token);
            batch.delete(docRef);
          });
          await batch.commit();
        }
      }

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };

    } catch (error) {
      console.error('Error in onOrderCreatedOrUpdated:', error);
      throw error;
    }
  });

/**
 * Optional: Cloud Function to clean up expired device tokens
 * Run daily to remove tokens that are no longer valid
 */
exports.cleanupExpiredTokens = functions.pubsub
  .schedule('every day 02:00')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Starting cleanup of expired device tokens...');
      
      const tokensSnapshot = await db.collection('deviceTokens').get();
      const batch = db.batch();
      let deleteCount = 0;

      // Try to send a test message to each token
      for (const doc of tokensSnapshot.docs) {
        try {
          const token = doc.data().token;
          
          // Try to send a silent data message to verify token is valid
          await messaging.send({
            data: { check: 'valid' },
            token: token,
          });
        } catch (error) {
          // If token is invalid, delete it
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            batch.delete(doc.ref);
            deleteCount++;
          }
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        console.log(`Cleaned up ${deleteCount} expired tokens`);
      }

      return { cleaned: deleteCount };
    } catch (error) {
      console.error('Error in cleanupExpiredTokens:', error);
      throw error;
    }
  });
