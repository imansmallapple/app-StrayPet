import uuid

USER_ID_KEY = 'uid'
MAX_AGE = 60 * 60 * 24 * 1


class UserUidMiddleware:

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        uid = self.generate_uid(request)
        request.uid = uid
        response = self.get_response(request)
        response.set_cookie('uid', uid, max_age=MAX_AGE, httponly=True)
        # print(response.cookies['uid'])
        return response

    def generate_uid(self, request):
        try:
            uid = request.COOKIES['uid']
        except KeyError:
            uid = uuid.uuid4().hex
        return uid
