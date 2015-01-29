import sys
import os

class Noops:
	params = {
		"var": -3,
		"print": -1,
		"add": 2,
		"sub": 2,
		"mul": 2,
		"div": 2,
		"round": 1,
		"asc": 1,
		"char": 1,
		"less": 2,
		"not": 1,
		"join": -1,
		"while": -1
	}
	
	def __init__(self, script):
		self.variables = {}
		self.script = script
	
	def execute(self):
		self.lines = self.script.splitlines()
		while len(self.lines):
			self.line = self.lines.pop(0)
			self.process(self.line.split(" "))
	
	def process(self, words, num=0):
		out = []
		if num < 0:
			num = 0xFFFF
		while len(words):
			word = words.pop(0).lower()
			if word in self.params:
				param_count = self.params[word]
				params = self.process(words, param_count)
				result = getattr(self, "_"+word)(*params)
			else:
				result = cast(word)
			out.append(result)
			
			if len(out) >= num:
				break
		return out
	
	def resolve(self, word, separator=" "):
		if (type(word) is list) or (type(word) is tuple):
			return cast(separator.join([str(self.resolve(thing)) for thing in word]))
		return self.variables.get(word, cast(word))
	
	def _var(self, varname, isornot, *value):
		value = self.resolve(value)
		if self.resolve(isornot) == "is":
			self.variables[varname] = value
	
	def _print(self, *text):
		sys.stdout.write(self.resolve(text))
		sys.stdout.flush()
	
	def _add(self, *addends):
		return sum([cast(self.resolve(thing)) for thing in addends])
	
	def _sub(self, minuend, subtrahend):
		return self.resolve(minuend) - self.resolve(subtrahend)
	
	def _mul(self, *multipliers):
		product = 1
		for mul in multipliers:
			resolved = self.resolve(mul)
			product *= resolved
		return product
	
	def _div(self, dividend, divisor):
		return float(self.resolve(dividend)) / self.resolve(divisor)
	
	def _less(self, left, right):
		return int(self.resolve(left) < self.resolve(right))
	
	def _while(self, statement):
		expression = self.line.split(" ")[1:]
		
		subscript = ""
		level = indent_level(self.lines[0])
		while len(self.lines) > 0 and indent_level(self.lines[0]) >= level:
			subscript += self.lines.pop(0)[level:] + "\n"
		
		subscript = Noops(subscript)
		subscript.variables = self.variables
		
		while self.resolve(self.process(list(expression))):
			subscript.execute()
	
	def _char(self, asciival):
		return chr(asciival)
	
	def _asc(self, char):
		return ord(char)
	
	def _not(self, value):
		return int(not value)
	
	def _round(self, value):
		return int(round(value))
	
	def _join(self, *values):
		return self.resolve(values, "")

def cast(string):
	if type(string) in (int, float):
		return string
	try:
		return int(string)
	except ValueError:
		try:
			return float(string)
		except ValueError:
			return string

def indent_level(string):
	return len(string)-len(string.lstrip())

def main():
	try:
		filepath = sys.argv[1]
	except IndexError:
		raise Exception("No file specified")
	if not os.path.isfile(filepath):
		raise Exception("File not found")
	with open(filepath, "r") as file:
		script = file.read()
	noops = Noops(script)
	noops.execute()

if __name__ == "__main__":
	main()