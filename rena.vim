"
" Rena Vim Script
"
" Copyright (c) 2019 Yuichiro MORIGUCHI
"
" This software is released under the MIT License.
" http://opensource.org/licenses/mit-license.php
"
function! Rena(...)
    let option = { "ignore": 0, "keys": 0 }
    if a:0 >= 1
        let option = a:1
    endif
    let me = {}

    function! s:ignore(match, lastIndex) closure
        if option["ignore"] is 0
            return a:lastIndex
        endif
        let Exp = option["ignore"]
        let result = Exp(a:match, a:lastIndex, 0)
        if result is 0
            return a:lastIndex
        else
            return result["lastIndex"]
        endif
    endfunction

    function me.str(str) dict
        let str = a:str
        function! s:strProcess(match, lastIndex, attr) closure
            if str ==# strpart(a:match, a:lastIndex, strlen(str))
                return { "matched": str, "lastIndex": a:lastIndex + strlen(str), "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return funcref("s:strProcess")
    endfunction

    function me.then(...) dict
        let args = copy(a:000)
        function! s:thenProcess(match, lastIndex, attr) closure
            let matched = ""
            let indexNew = a:lastIndex
            let attrNew = a:attr
            for Arg in args
                let result = Arg(a:match, indexNew, attrNew)
                if result is 0
                    return 0
                else
                    let indexNew = s:ignore(a:match, result["lastIndex"])
                    let attrNew = result["attr"]
                endif
            endfor
            return { "matched": strpart(a:match, a:lastIndex, indexNew), "lastIndex": indexNew, "attr": attrNew }
        endfunction
        return funcref("s:thenProcess")
    endfunction

    function me.choice(...) dict
        let args = copy(a:000)
        function! s:choiceProcess(match, lastIndex, attr) closure
            for Arg in args
                let result = Arg(a:match, a:lastIndex, a:attr)
                if result isnot 0
                    return result
                endif
            endfor
            return 0
        endfunction
        return funcref("s:choiceProcess")
    endfunction

    function me.times(mincount, maxcount, Exp, ...) dict
        let Exp = a:Exp
        let Action = { matched, syn, inh -> syn }
        if a:0 >= 1
            let Action = a:1
        endif
        function! s:timesProcess(match, lastIndex, attr) closure
            let matched = ""
            let indexNew = a:lastIndex
            let attrNew = a:attr
            let i = 0
            while a:maxcount is 0 || i < a:maxcount
                let result = Exp(a:match, indexNew, attrNew)
                if result is 0
                    if i < a:mincount
                        return 0
                    else
                        return { "matched": matched, "lastIndex": indexNew, "attr": attrNew }
                    endif
                else
                    let indexNew = s:ignore(a:match, result["lastIndex"])
                    let matched = strpart(a:match, a:lastIndex, indexNew)
                    let attrNew = Action(matched, result["attr"], attrNew)
                    let i = i + 1
                endif
            endwhile
            return { "matched": matched, "lastIndex": indexNew, "attr": attrNew }
        endfunction
        return funcref("s:timesProcess")
    endfunction

    function me.atLeast(mincount, Exp, ...) dict
        let Action = { matched, syn, inh -> syn }
        if a:0 >= 1
            let Action = a:1
        endif
        return self.times(a:mincount, 0, a:Exp, Action)
    endfunction

    function me.atMost(maxcount, Exp, ...) dict
        let Action = { matched, syn, inh -> syn }
        if a:0 >= 1
            let Action = a:1
        endif
        return self.times(0, a:maxcount, a:Exp, Action)
    endfunction

    function me.oneOrMore(Exp, ...) dict
        let Action = { matched, syn, inh -> syn }
        if a:0 >= 1
            let Action = a:1
        endif
        return self.times(1, 0, a:Exp, Action)
    endfunction

    function me.zeroOrMOre(Exp, ...) dict
        let Action = { matched, syn, inh -> syn }
        if a:0 >= 1
            let Action = a:1
        endif
        return self.times(0, 0, a:Exp, Action)
    endfunction

    function me.maybe(Exp) dict
        return self.times(0, 1, a:Exp)
    endfunction

    function me.lookahead(Exp) dict
        let Exp = a:Exp
        function! s:lookaheadProcess(match, lastIndex, attr) closure
            let result = Exp(a:match, a:lastIndex, a:attr)
            if result is 0
                return 0
            else
                return { "matched": "", "lastIndex": a:lastIndex, "attr": a:attr }
            endif
        endfunction
        return funcref("s:lookaheadProcess")
    endfunction

    function me.lookaheadNot(Exp) dict
        let Exp = a:Exp
        function! s:lookaheadProcess(match, lastIndex, attr) closure
            let result = Exp(a:match, a:lastIndex, a:attr)
            if result is 0
                return { "matched": "", "lastIndex": a:lastIndex, "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return funcref("s:lookaheadProcess")
    endfunction

    function me.action(Exp, Action) dict
        let Exp = a:Exp
        let Action = a:Action
        function! s:actionProcess(match, lastIndex, attr) closure
            let result = Exp(a:match, a:lastIndex, a:attr)
            if result is 0
                return 0
            else
                let retval = copy(result)
                let retval["attr"] = Action(retval["matched"], retval["attr"], a:attr)
                return retval
            endif
        endfunction
        return funcref("s:actionProcess")
    endfunction

    return me
endfunction

