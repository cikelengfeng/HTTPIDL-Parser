import re

Satisfied = 0
Eating = 1
Failed = 2

class LetterMatcher:

    def match(self, letter):
        return False


class BaseMatcher(LetterMatcher):

    def __init__(self, letter):
        self.letter = letter

    def match(self, letter):
        if self.letter is letter
            return Satisfied
        return  Failed


class RegexMatcher(LetterMatcher):

    def __init__(self, regex):
        self.regex = regex
        self.eating = ''

    def match(self, letter):
        eating = self.eating + letter
        if self.regex.search(eating) is None:
            if self.eating is '':
                return Failed
            else:
                return Satisfied
        else:
            self.eating = eating
            return Eating



class TrieConstructItem:
    def fill_into(self, trie):
        pass


class StringConstructItem(TrieConstructItem):

    def __init__(self, string):
        self.string = string

    def fill_into(self, trie):
        current = trie
        for letter in self.string:
            matcher = BaseMatcher(letter)
            current = current.setdefault(matcher, {})
        current['_end_'] = True


class RegexConstructItem(TrieConstructItem):

    def __init__(self, regex_str):
        self.regex = re.compile(regex_str)

    def fill_into(self, trie):
        matcher = RegexMatcher(self.regex)
        trie.setdefault(matcher, {})
        trie['_end_'] = True

class Trie:

    def __init__(self, item_list):
        self.root = self.construct(item_list)
        self.current = self.root

    def construct(self, item_list):
        root = {}
        for item in item_list:
            item.fill_into(root)
        return root

    def shift(self, letter):
        for matcher, sub_matcher in self.current:
            match_result = matcher.match(letter)
            if match_result is Failed:
                print self.current
                self.current = self.root
            elif match_result is Satisfied:
                self.current = self.root



if __name__ == '__main__':
    foo = StringConstructItem('foo')
    bar = StringConstructItem('bar')
    baz = StringConstructItem('baz')
    barz = StringConstructItem('barz')
    regex = RegexConstructItem(r' *')
    trie = Trie([foo, bar, baz, barz, regex])
    print trie.root
