#Source : https://github.com/naens/scheme-lisp/tree/master/chap02pwsh

Enum TokenType {
    Number
    Symbol
    String
    Character
    Boolean
    ParOpen
    ParClose
    Dot
    Quote
}

class Token {
    $type
    $value

    Token($type, $value) {
        $this.type = $type
        $this.value = $value
    }

    Token($type) {
        $this.type = $type
    }

    [string] ToString() {
        return "[TOKEN:type=$($this.type),value=$($this.value)]"
    }
}

function Is-Delimiter($char) {
    $char -match "[(){}'""\[\]\t\n\r ]+"
}

function Is-Digit($char) {
    return $char -match "^[\d\.]+$"
}

function Read-Number($Text, $length, $index) {
    $sum = 0
    while ($index -lt $length -and (Is-Digit $Text[$index])) {
        $c = $Text[$index]
        $sum = $sum * 10 + [convert]::ToInt32($c, 10)
        $index++
    }
    return $sum, $index
}

function Read-Symbol($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and !(Is-Delimiter $Text[$index])) {
        $c = $Text[$index]
        $str = $str + $c
        $index++
    }
    return $str, $index # return $str.ToUpper(), $index 
}

function Read-String($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and $Text[$index] -ne """") {
        $c = $Text[$index]
        if ($c -eq "\") {
            if ($index -lt ($length - 1)) {
                $c = $Text[$index + 1]
                $str = $str + $c
                $index++
            }
        }
        else {
            $str = $str + $c
        }
        $index++
    }
    return $str, ($index+1)
}

function Read-Comment($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and !($Text[$index] -match "[\n\r]")) {
        $index++
    }
    return $index+1
}

function Get-Tokens($Text) {
    $Tokens = @()
    $length = $Text.length
    $i = 0
    while($i -lt $length) {
        switch -regex  ($Text[$i])
        {
            "-" {
                if ($i -le ($length-1) -and (Is-Digit($Text[$i+1]))) {
                    $v,$i = Read-Number $Text $length ($i+1)
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Number), -$v
                } else {
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $Text[$i]
                    $i++
                }
            }
            "[0-9]" {
                $v,$i = Read-Number $Text $length $i
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Number), $v
            }
            """" {
                $v,$i = Read-String $Text $length ($i+1)
                $Tokens += New-Object Token -ArgumentList ([TokenType]::String), $v
            }
            "#" {
                if ($i -lt ($length-1)) {
                    switch -regex  ($Text[$i+1]) {
                        "[tT]" {
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Boolean), $true
                            $i += 2
                        }
                        "[fF]" {
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Boolean), $false
                            $i += 2
                        }
                        "\\" {
                            if ($i -lt ($length-2)) {
                                $Tokens += New-Object Token -ArgumentList ([TokenType]::Character), $Text[$i+2]
                                $i += 3
                            }
                        }
                        default {
                            $v, $i = Read-Symbol $Text $length $i
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                        }
                    }
                } else {
                    $v, $i = Read-Symbol $Text $length $i
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                }
            }
            "\(" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::ParOpen)
                $i++
            }
            "\)" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::ParClose)
                $i++
            }
            "\." {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Dot)
                $i++
            }
            "'" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Quote)
                $i++
            }
            ";" {
                # find end of line
                $i = Read-Comment $Text $length $i
            }
            default {
                if (!(Is-Delimiter($Text[$i]))) {
                    $v,$i = Read-Symbol $Text $length $i
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                } else {
                    $i++
                }
            }
        }
    }

    $Tokens
}

Enum ExpType {
    Number
    Symbol
    String
    Character
    Boolean
    Cons
    Function
    BuiltIn
}

class Fun {
    $defEnv
    $params
    $dotParam = $null
    $isThunk = $false
    $body
}

class Exp {
    $type
    $value
    $car
    $cdr

    Exp($type) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -eq "[ExpType]::BuiltIn") {
            throw "Exp: BuiltIn creation bad arguments"
        }
    }

    Exp($type, $value) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -eq "Cons") {
            throw "Exp: Cons creation bad arguments"
        }
        $this.value = $value
    }

    Exp($type, $car, $cdr) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -ne "Cons") {
            throw "Exp: Cons creation bad type " + $type
        }
        $this.car = $car
        $this.cdr = $cdr
    }

    [string] ToString0() {
        [ExpType]$t = $this.type
        switch ($t) {
            "Number" {
                return "num:"+$this.value
            }
            "Symbol" {
                return "sym:"+$this.value
            }
            "String" {
                return "str:"+$this.value
            }
            "Character" {
                return "chr:"+$this.value
            }
            "Boolean" {
                return "bool:" + $this.value
            }
            "Cons" {
                return "cons:{$($this.car),$($this.cdr)}"
            }
            default {
                return "{$t}"
            }
        }
        return "<unknown-expr>: " + $this.type
    }

    [string] MakeSublistString($cons) {
        if ($cons.car -eq $null) {
            $carString = "null"
        } else {
            $carString = $cons.car.ToString()
        }
        if ($cons.cdr.type -eq "Cons") {
            $restString = $this.MakeSublistString($cons.cdr)
            return $carString + " " + $restString
        } if ($cons.cdr.type -eq "Symbol" -and $cons.cdr.value -eq "NIL") {
            return $carString
        } else {
            return $carString + " . " + $cons.cdr.ToString()
        }
    }

    [string] ToString() {
        [ExpType]$t = $this.type
        #Write-Host TOSTRING t=$t
        switch ($t) {
            "Number" {
                return $this.value
            }
            "Symbol" {
                if ($this.value -eq "NIL") {
                    return "'()"
                }
                return $this.value
            }
            "String" {
                return """$($this.value)"""
            }
            "Character" {
                return "#\$($this.value)"
            }
            "Boolean" {
                if ($this.value) {
                    return "#t"
                } else {
                    return "#f"
                }
            }
            "Cons" {
                $subList = $this.MakeSublistString($this)
                return "($subList)"
            }
            "Function" {
                if ($this.value.isThunk) {
                    return "#<Thunk: $($this.value.body)>"
                } else {
                    # TODO: display dot parameter
                    return "#<Function($($this.value.params)): $($this.value.body)>"
                }
            }
            "BuiltIn" {
                #Write-Host TOSTRING $($this.value)
                return "#<BuiltIn:$($this.value)>"
            }
            default {
                return "<<<$t>>>"
            }
        }
        return "<<<unknown-expr:" + $this.type + ">>>"
    }
}

function Parse-List($Tokens, $length, $i) {
    $token = $Tokens[$i]
    $prev = $null
    $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    $first = $nil
    while ($i -lt $length) {
        switch ("[TokenType]::$($token.type)") {
            "[TokenType]::Dot" {
                $i++
                $exp, $i = Parse-Exp $Tokens $length $i
                if ($Tokens[$i].Type -eq "ParClose" -and $prev -ne $null) {
                    $i++
                    $prev.cdr = $exp
                    return $first, $i
                } else {
                    return $null, $null
                }
            }
            "[TokenType]::ParClose" {
                $i++
                return $first, $i
            }
            default {
                $exp, $i = Parse-Exp $Tokens $length $i
                $cons = New-Object Exp -ArgumentList ([ExpType]::Cons), $exp, $nil
                if ($prev -ne $null) {
                    $prev.cdr = $cons
                }
                if ($first -eq $nil) {
                    $first = $cons
                }
                $prev = $cons
            }
        }
        $token = $Tokens[$i]
    }
    return $null, $null
}

function Parse-Exp($Tokens, $length, $i) {
    $token = $Tokens[$i]
    switch ("[TokenType]::$($token.type)") {
        "[TokenType]::Number" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Number), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Symbol" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Symbol), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::String" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::String), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Character" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Character), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Boolean" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Boolean), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::ParOpen" {
            $exp, $i = Parse-List $Tokens $length ($i+1)
            return $exp, $i
        }
        "[TokenType]::ParClose" {
            return $null, $null
        }
        "[TokenType]::Dot" {
            return $null, $null
        }
        "[TokenType]::Quote" {
            $car = New-Object Exp -ArgumentList ([ExpType]::Symbol), "QUOTE"
            $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
            $subexp, $i = Parse-Exp $Tokens $length ($i+1)
            $cdr = New-Object Exp -ArgumentList ([ExpType]::Cons), $subexp, $nil
            $exp = New-Object Exp -ArgumentList ([ExpType]::Cons), $car, $cdr
            return $exp, $i
        }
    }
    $exp = New-Object Exp -ArgumentList ([ExpType]::Number), -1
    return $exp, ($i+1)
}

function Parse-Tokens($Tokens) {
    $i = 0
    $Exps = @()
    $length = $Tokens.length
    while ($i -lt $length) {
        $exp, $i = Parse-Exp $Tokens $length $i
        if ($exp) {
            $Exps += $exp
        }
        else {
            break
        }
    }
    $Exps
}

<# Test section
$sexp1 = "( where ( and ( or ( eq OrionAuditLog.CmdName ""Assign policy"" ) ( eq OrionAuditLog.CmdName ""Remove policy assignment"" ) "` + 
         "( eq OrionAuditLog.CmdName ""Add policy assignment rule"" ) ( eq OrionAuditLog.CmdName ""Deletepolicy assignment rule"" ) "` + 
         "( eq OrionAuditLog.CmdName ""Edit policy assignment rule"" ) ( eq OrionAuditLog.CmdName ""Edit Policy Assignment Rule Priority"" ) "` + 
         " ) ( newerThan OrionAuditLog.StartTime 2592000000  ) ( ne OrionAuditLog.UserName ""system"" ) ) )"
$sexp2 = "(or (eq OrionAuditLog.CmdName ""Assign policy"") (eq OrionAuditLog.CmdName ""Remove policy assignment""))"
$sexp3 = "(order (az OrionAuditLog.StartTime) (az OrionAuditLog.UserName) (az OrionAuditLog.Message) )"
$sexp4 = "( select OrionAuditLog.StartTime OrionAuditLog.UserName OrionAuditLog.Message )"
$t = Get-Tokens($sexp1)
$t


$pt = Parse-Tokens($t)
$pt
#>




function Get-SExpressionObject {
    <#
    .SYNOPSIS
        Parses an S-expression string into an object tree

    .DESCRIPTION
        Tokenizes and parses an S-expression string (used in ePO query clauses)
        into a structured object tree using a Scheme-like parser.

    .PARAMETER sexp
        The S-expression string to parse.

    .OUTPUTS
        [Exp]. Parsed expression object tree.

    .EXAMPLE
        Get-SExpressionObject -sexp "(where (eq EPOLeafNode.NodeName ""PC01""))"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$sexp
    )
    return Parse-Tokens(Get-Tokens($sexp))
}

#Export-ModuleMember -Function Get-SExpressionObject
#Export-ModuleMember -Function Get-SExpressionObject2
