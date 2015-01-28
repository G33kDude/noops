#SingleInstance
SetBatchLines, -1
DllCall("AllocConsole")

FilePath = %1% ; Pull from command line parameter

if !FilePath
	FileSelectFile, FilePath,,, Select a noops source file, Noops Source (*.noops)

FileRead, Script, %FilePath%
MyNoops := new noops(Script)
MyNoops.Execute()
MsgBox

class noops
{
	static Params := {Var: -3
	, Print: -1, Add: 2, Sub: 2
	, While: -1, Div: 2, Mul: 2
	, Less: 2, Char: 1, Asc: 1
	, Not: 1, Round: 1, Join: -1}
	
	__New(Script)
	{
		this.Variables := []
		this.Script := Script
	}
	
	Execute()
	{
		this.Lines := StrSplit(this.Script, "`n", "`r")
		while this.Lines.MaxIndex()
		{
			this.Line := this.Lines.Remove(1)
			this.Process(StrSplit(this.Line, " "))
		}
	}
	
	Process(Words, Num=0)
	{
		Out := []
		if Num < 0
			Num := ~0
		while Words.MaxIndex()
		{
			Word := Words.Remove(1)
			
			if this.Params.HasKey(Word)
			{
				ParamCount := this.Params[Word]
				Params := this.Process(Words, ParamCount)
				Result := this["_" Word].(this, Params*)
				Out.Insert(Result)
			}
			else
				Out.Insert(Word)
			
			if (Out.MaxIndex() >= Num)
				break
		}
		return Out
	}
	
	Resolve(Word, Separator=" ")
	{
		if IsObject(Word)
		{
			for each, Word in Word
				Out .= Separator this.Resolve(Word)
			return SubStr(Out, StrLen(Separator)+1)
		}
		return this.Variables.HasKey(Word) ? this.Variables[Word] : Word
	}
	
	_Var(varname, isornot, value*)
	{
		Value := this.Resolve(Value)
		if (this.Resolve(isornot) = "is")
			this.Variables[varname] := Value
	}
	
	_Print(Text*)
	{
		FileOpen("$CONOUT", "w").Write(this.Resolve(Text))
	}
	
	_Add(Addend1, Addend2)
	{
		return this.Resolve(Addend1)+this.Resolve(Addend2)
	}
	
	_Sub(Minuend, Subtrahend)
	{
		return this.Resolve(Minuend) - this.Resolve(Subtrahend)
	}
	
	_Mul(Multiplier1, Multiplier2)
	{
		return this.Resolve(Multiplier1) * this.Resolve(Multiplier2)
	}
	
	_Div(Dividend, Divisor)
	{
		return this.Resolve(Dividend) / this.Resolve(Divisor)
	}
	
	_Less(Left, Right)
	{
		return this.Resolve(Left) < this.Resolve(Right)
	}
	
	_ID(Variable)
	{
		this.Variables[Variable] -= 1
	}
	
	_While(Statement)
	{
		Expression := StrSplit(this.Line, " ")
		Expression.Remove(1) ; the word "While"
		
		Level := IndentLevel(this.Lines[1])
		while IndentLevel(this.Lines[1]) >= Level
			SubScript .= SubStr(this.Lines.Remove(1), Level) "`n"
		
		SubScript := new noops(SubScript)
		SubScript.Variables := this.Variables
		
		while this.Resolve(this.Process(Expression.Clone()))
			SubScript.Execute()
	}
	
	_Char(Asc)
	{
		return Chr(this.Resolve(Asc))
	}
	
	_Asc(Char)
	{
		return Asc(this.Resolve(Char))
	}
	
	_Not(Value)
	{
		return !this.Resolve(Value)
	}
	
	_Round(Value)
	{
		return Round(this.Resolve(Value))
	}
	
	_Join(Values*)
	{
		return this.Resolve(Values, "")
	}
}

IndentLevel(String)
{
	return RegExMatch(String, "^ *\K[^ ]")
}