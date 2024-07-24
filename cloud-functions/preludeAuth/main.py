@functions_framework.http
def preludeAuth(request, phoneNumber):
    api_key = 'YOUR_API_KEY_NEO'
    customer_uuid = request.args.get('customer_uuid', 'YOUR_CUSTOMER_ID_NEO')

    s = ding.Ding(api_key=api_key)

    req = components.CreateAuthenticationRequest(
        customer_uuid=customer_uuid,
        phone_number=phoneNumber,
    )

    res = s.otp.create_autentication(req)

    return res.create_authentication_response is not None