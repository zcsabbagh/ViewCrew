from firebase_admin import firestore, messaging, initialize_app
import functions_framework

# Initialize Firebase Admin SDK
initialize_app()

@functions_framework.http
def sendReactPostNotification(request):
    print("Function start: send_react_post_notification")
    data = request.get_json()
    print(f"Received data: {data}")

    post_recipient_id = data['data']['postRecipientId']
    like_sender_id = data['data']['likeSenderId']
    emoji = data['data']['emoji']
    print(f"Post Recipient ID: {post_recipient_id}")
    print(f"Like Sender ID: {like_sender_id}")
    print(f"Emoji: {emoji}")

    db = firestore.client()
    print("Firestore client initialized")

    like_sender_document = db.collection("users").document(like_sender_id).get()
    print(f"Like Sender Document: {like_sender_document.exists}")

    post_recipient_document = db.collection("users").document(post_recipient_id).get()
    print(f"Post Recipient Document: {post_recipient_document.exists}")

    if post_recipient_document.exists and post_recipient_document.to_dict().get('fcmToken'):
        print("Post recipient exists and has an FCM token")

        like_sender_display_name = like_sender_document.to_dict().get('displayName')
        recipient_fcm_token = post_recipient_document.to_dict().get('fcmToken')
        print(f"Like Sender Display Name: {like_sender_display_name}")
        print(f"Recipient FCM Token: {recipient_fcm_token}")

        notification = messaging.Notification(
            title=f"{like_sender_display_name} sent {emoji}",
            body="Tap in to see what they're up to"
        )
        print(f"Notification prepared: {notification}")

        message = messaging.Message(
            notification=notification,
            data={
                'link': f"Roll://post?PostID={post_recipient_id}",
                'body': "Tap in to see what they're up to",
            },
            token=recipient_fcm_token,
        )
        print(f"Message prepared: {message}")

        try:
            response = messaging.send(message)
            print(f"Notification response: {response}")

            db.collection("users").document(post_recipient_id).collection("notifications").add({
                'type': "PostReact",
                'body': "Tap in to see what they're up to",
                'timestamp': firestore.SERVER_TIMESTAMP,
                'link': f"Roll://post?PostID={post_recipient_id}",
                'senderId': like_sender_id,
                'isRead': False,
            })
            print("Notification data added to Firestore")
            return 'Notification sent successfully!'
        except Exception as error:
            print(f"Error encountered: {error}")
            return f'Error sending notification: {str(error)}', 500
    else:
        print("No valid recipient data found")
        return 'User data not found', 404
    


    from firebase_admin import firestore, messaging, initialize_app
import functions_framework

# Initialize Firebase Admin SDK
initialize_app()

@functions_framework.http
def sendContactJoinedNotification(request):
    try:
        data = request.get_json()['data']
        joined_user_display_name = data.get('joinedUserDisplayName')
        joined_user_id = data.get('joinedUserId')
        message_recipient_ids = data.get('messageRecipientIds')

        if not joined_user_display_name or not isinstance(message_recipient_ids, list):
            print("Invalid input")
            return {'error': "Invalid input"}, 400

        message = f"{joined_user_display_name} is now on View Crew"
        db = firestore.client()

        for recipient_id in message_recipient_ids:
            send_notification_to_user(db, recipient_id, joined_user_id, message)

        return {'message': "Contact notifications sent!"}
    except Exception as error:
        print(f"Error in send_contact_joined_notification function: {error}")
        return {'error': "Failed to send contact joined notifications"}, 500

def send_notification_to_user(db, recipient_id, joined_user_id, message):
    try:
        message_recipient_document = db.collection("users").document(recipient_id).get()
        recipient_fcm_token = message_recipient_document.to_dict().get('fcmToken')

        if recipient_fcm_token:
            payload = messaging.Message(
                notification=messaging.Notification(
                    title="🆕 Guess who's here?",
                    body=message,
                ),
                data={
                    'body': message,
                    'link': f"Roll://friend?SenderID={joined_user_id}",
                },
                token=recipient_fcm_token,
            )

            messaging.send(payload)
            print(f"Successfully sent message to: {recipient_id}")

            db.collection("users").document(recipient_id).collection("notifications").add({
                'type': "ContactJoined",
                'body': message,
                'timestamp': firestore.SERVER_TIMESTAMP,
                'link': f"Roll://friend?SenderID={joined_user_id}",
                'senderId': joined_user_id,
                'isRead': False,
            })
            print("Successfully added notification to Firestore.")
        else:
            print(f"No FCM token found for recipient: {recipient_id}")
    except Exception as error:
        print(f"Error sending message to {recipient_id}: {error}")



from firebase_admin import firestore, messaging, initialize_app
import functions_framework

# Initialize Firebase Admin SDK
initialize_app()

@functions_framework.http
def sendFriendRequestNotification(request):
    print("Function start: sendFriendRequestNotification")
    data = request.get_json()
    print(f"Received data: {data}")
    
    sending_user_id = data['data']['sendingUser']
    receiving_user_id = data['data']['receivingUser']
    print(f"Sending User ID: {sending_user_id}")
    print(f"Receiving User ID: {receiving_user_id}")
    
    db = firestore.client()
    print("Firestore client initialized")
    
    sending_user_document = db.collection("users").document(sending_user_id).get()
    print(f"Sending User Document: {sending_user_document.exists}")
    
    receiving_user_document = db.collection("users").document(receiving_user_id).get()
    print(f"Receiving User Document: {receiving_user_document.exists}")
    
    if receiving_user_document.exists and receiving_user_document.to_dict().get('fcmToken'):
        print("Receiving user exists and has an FCM token")
        
        sending_user_display_name = sending_user_document.to_dict().get('displayName')
        receiving_user_fcm_token = receiving_user_document.to_dict().get('fcmToken')
        
        print(f"Sending User Display Name: {sending_user_display_name}")
        print(f"Receiving User FCM Token: {receiving_user_fcm_token}")
        
        notification = messaging.Notification(
            title="📩 Need a friend?",
            body=f"Exciting news! {sending_user_display_name} wants to be besties."
        )
        print(f"Notification prepared: {notification}")
        
        message = messaging.Message(
            notification=notification,
            data={
                'link': f"Roll://friendRequest?SenderID={sending_user_id}",
                'body': f"Exciting news! {sending_user_display_name} wants to be besties.",
            },
            token=receiving_user_fcm_token,
        )
        print(f"Message prepared: {message}")

        try:
            response = messaging.send(message)
            print(f"Notification response: {response}")
            
            db.collection("users").document(receiving_user_id).collection("notifications").add({
                'type': "FriendRequest",
                'body': f"Exciting news! {sending_user_display_name} wants to be besties.",
                'timestamp': firestore.SERVER_TIMESTAMP,
                'link': f"Roll://friendRequest?SenderID={sending_user_id}",
                'senderId': sending_user_id,
                'isRead': False,
            })
            print("Notification data added to Firestore")
            return 'Notification sent successfully!'
        except Exception as error:
            print(f"Error encountered: {error}")
            return f'Error sending notification: {str(error)}', 500
    else:
        print("No valid recipient data found")
        return 'User data not found', 404
    


    from firebase_admin import firestore, messaging, initialize_app
from firebase_functions import https_fn

# Initialize Firebase Admin SDK
initialize_app()

@https_fn.on_call()
def acceptFriendRequestNotification(request: https_fn.CallableRequest) -> dict:
    print("Function start: accept_friend_request_notification")
    data = request.data
    print(f"Received data: {data}")
    
    message_recipient_id = data['messageRecipientId']
    message_sender_id = data['messageSenderId']
    print(f"Message Recipient ID: {message_recipient_id}")
    print(f"Message Sender ID: {message_sender_id}")
    
    db = firestore.client()
    print("Firestore client initialized")
    
    message_sender_document = db.collection("users").document(message_sender_id).get()
    print(f"Message Sender Document: {message_sender_document.exists}")
    
    message_recipient_document = db.collection("users").document(message_recipient_id).get()
    print(f"Message Recipient Document: {message_recipient_document.exists}")
    
    if message_recipient_document.exists and message_recipient_document.to_dict().get('fcmToken'):
        print("Recipient exists and has an FCM token")
        
        message_sender_display_name = message_sender_document.to_dict().get('displayName')
        message_recipient_display_name = message_recipient_document.to_dict().get('displayName')
        receiving_user_fcm_token = message_recipient_document.to_dict().get('fcmToken')
        sending_user_fcm_token = message_sender_document.to_dict().get('fcmToken')
        
        print(f"Message Sender Display Name: {message_sender_display_name}")
        print(f"Receiving User FCM Token: {receiving_user_fcm_token}")
        
        # Notification for recipient
        notification_recipient = messaging.Notification(
            title="☑️ Friend Request Accepted",
            body=f"You and {message_sender_display_name} are now friends."
        )
        print(f"Notification prepared for recipient: {notification_recipient}")
        
        message_recipient = messaging.Message(
            notification=notification_recipient,
            data={
                'link': f"Roll://friend?SenderID={message_sender_id}",
                'body': f"You and {message_sender_display_name} are now friends.",
            },
            token=receiving_user_fcm_token,
        )
        print(f"Message prepared for recipient: {message_recipient}")

        # Notification for sender
        notification_sender = messaging.Notification(
            title="☑️ Friend Request Accepted",
            body=f"You and {message_recipient_display_name} are now friends."
        )
        print(f"Notification prepared for sender: {notification_sender}")
        
        message_sender = messaging.Message(
            notification=notification_sender,
            data={
                'link': f"Roll://friend?RecipientID={message_recipient_id}",
                'body': f"You and {message_recipient_display_name} are now friends.",
            },
            token=sending_user_fcm_token,
        )
        print(f"Message prepared for sender: {message_sender}")

        try:
            # Send notification to recipient
            response_recipient = messaging.send(message_recipient)
            print(f"Notification response for recipient: {response_recipient}")
            
            # Send notification to sender
            response_sender = messaging.send(message_sender)
            print(f"Notification response for sender: {response_sender}")
            
            # Add notification data to Firestore for both users
            db.collection("users").document(message_recipient_id).collection("notifications").add({
                'type': "FriendAccept",
                'body': f"You and {message_sender_display_name} are now friends.",
                'timestamp': firestore.SERVER_TIMESTAMP,
                'link': f"Roll://friend?SenderID={message_sender_id}",
                'senderId': message_sender_id,
                'isRead': False,
            })
            db.collection("users").document(message_sender_id).collection("notifications").add({
                'type': "FriendAccept",
                'body': f"You and {message_recipient_display_name} are now friends.",
                'timestamp': firestore.SERVER_TIMESTAMP,
                'link': f"Roll://friend?RecipientID={message_recipient_id}",
                'recipientId': message_recipient_id,
                'isRead': False,
            })
            print("Notification data added to Firestore for both users")
            return {'success': True, 'message': 'Notification sent successfully to both users!'}
        except Exception as error:
            print(f"Error encountered: {error}")
            return {'success': False, 'error': str(error)}
    else:
        print("No valid recipient data found")
        return {'success': False, 'error': 'User data not found'}



