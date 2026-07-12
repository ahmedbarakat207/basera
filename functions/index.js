const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.sendPushNotificationOnSafetyReport = functions.firestore
  .document("users/{childUid}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    const childName = afterData.name || "Your child";
    const parentUid = afterData.parentUid;

    // Check if the role is actually a child and if they have a linked parent
    if (afterData.role !== "child" || !parentUid) return null;

    // We only care if the latest_report changed
    const reportBefore = beforeData.latest_report;
    const reportAfter = afterData.latest_report;

    if (!reportAfter || JSON.stringify(reportBefore) === JSON.stringify(reportAfter)) {
      return null;
    }

    // Check if the report has any harmful URLs
    const isAtRisk = reportAfter.overallRiskScore >= 5.0;
    const harmfulAnalyses = (reportAfter.analyses || []).filter(a => a.isHarmful);

    if (harmfulAnalyses.length === 0 && !isAtRisk) {
      // It's a safe browsing report, no need to alert parent with a push
      return null;
    }

    // It's unsafe! Send a notification to the parent
    try {
      // 1. Get the parent's FCM Token
      const parentDoc = await db.collection("users").doc(parentUid).get();
      if (!parentDoc.exists) return null;

      const parentData = parentDoc.data();
      const fcmToken = parentData.fcmToken;

      if (!fcmToken) {
        console.log(`Parent ${parentUid} does not have an FCM token.`);
        return null;
      }

      // 2. Prepare the notification payload
      const payload = {
        notification: {
          title: "⚠️ Security Alert",
          body: `${childName} recently visited a flagged URL. Risk Score: ${reportAfter.overallRiskScore.toFixed(1)}/10`,
        },
        data: {
          childUid: context.params.childUid,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }
      };

      // 3. Send via FCM
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      console.log("Successfully sent message:", response);
      return null;
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null;
    }
  });
