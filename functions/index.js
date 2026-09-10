const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const Razorpay = require("razorpay");

setGlobalOptions({
  maxInstances: 10,
});

// Razorpay credentials stored securely in Firebase Secret Manager
const razorpayKeyId = defineSecret("RAZORPAY_KEY_ID");
const razorpayKeySecret = defineSecret("RAZORPAY_KEY_SECRET");

// Create Razorpay Order
exports.createRazorpayOrder = onCall(
    {
      secrets: [razorpayKeyId, razorpayKeySecret],
    },
    async (request) => {
      try {
        // Make sure user is logged in
        if (!request.auth) {
          throw new HttpsError(
              "unauthenticated",
              "You must be logged in to create a payment order.",
          );
        }

        // Get amount from Flutter
        const amount = request.data.amount;

        // Validate amount
        if (
          typeof amount !== "number" ||
                !Number.isInteger(amount) ||
                amount <= 0
        ) {
          throw new HttpsError(
              "invalid-argument",
              "Amount must be a positive integer in paise.",
          );
        }

        console.log(
            `Creating Razorpay order for amount: ${amount} paise`,
        );

        // Initialize Razorpay
        const razorpay = new Razorpay({
          key_id: razorpayKeyId.value(),
          key_secret: razorpayKeySecret.value(),
        });

        // Create Razorpay order
        const order = await razorpay.orders.create({
          amount: amount,
          currency: "INR",
          receipt: `receipt_${Date.now()}`,
        });

        console.log(
            `Razorpay order created successfully: ${order.id}`,
        );

        // Return only safe information to Flutter
        return {
          success: true,
          orderId: order.id,
          amount: order.amount,
          currency: order.currency,
          keyId: razorpayKeyId.value(),
        };
      } catch (error) {
        console.error("Razorpay order creation failed:", error);

        if (error instanceof HttpsError) {
          throw error;
        }

        throw new HttpsError(
            "internal",
            "Unable to create Razorpay order.",
        );
      }
    },
);
