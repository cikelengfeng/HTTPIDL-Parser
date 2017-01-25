class Token:
    def __init__(self, target_path, line, column, length, text):
        self.target_path = target_path
        self.line = line
        self.column = column
        self.length = length
        self.text = text


class TokenStream:

    def next_token(self):


    def has_next(self):
        return False


class Lexer:
    def __init__(self, target_path):
        self.target_path = target_path


    def token_stream(self):
