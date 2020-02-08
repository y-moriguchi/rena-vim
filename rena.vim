"
" This source code is under the Unlicense.
"
function! Rena(...)
    let me = {}
    let Ignore = 0
    let keys = 0
    let realRegex = "[-+]\\?\\([0-9]\\+\\(\\.[0-9]\\+\\)\\?\\|\\.[0-9]\\+\\)\\([eE][-+]\\?[0-9]\\+\\)\\?"

    if a:0 >= 1
        if has_key(a:1, "ignore")
            let Ignore = a:1["ignore"]
        endif
        if has_key(a:1, "keys")
            let keys = a:1["keys"]
        endif
    endif

    function me.ignore(match, lastIndex) closure
        if Ignore is 0
            return a:lastIndex
        endif
        let result = Ignore(a:match, a:lastIndex, 0)
        if result is 0
            return a:lastIndex
        else
            return result.lastIndex
        endif
    endfunction

    function me.str(str) closure
        let str = a:str
        let ret = {}
        function! ret.strProcess(match, lastIndex, attr) closure
            if str ==# strpart(a:match, a:lastIndex, strlen(str))
                return { "match": str, "lastIndex": a:lastIndex + strlen(str), "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return ret.strProcess
    endfunction

    function me.re(regex) closure
        let regex = a:regex
        let ret = {}
        function! ret.regexProcess(match, lastIndex, attr) closure
            let position = matchstrpos(a:match, regex, a:lastIndex)
            if position[1] == a:lastIndex
                return { "match": position[0], "lastIndex": position[2], "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return ret.regexProcess
    endfunction

    function me.concat0(isSkip, ...) closure
        let args = copy(a:000)
        let isSkip = a:isSkip
        let ret = {}
        function! ret.thenProcess(match, lastIndex, attr) closure
            let matched = ""
            let indexNew = a:lastIndex
            let attrNew = a:attr
            for Arg in args
                let result = Arg(a:match, indexNew, attrNew)
                if result is 0
                    return 0
                else
                    if isSkip
                        let indexNew = me.ignore(a:match, result["lastIndex"])
                    else
                        let indexNew = result["lastIndex"]
                    endif
                    let attrNew = result["attr"]
                endif
            endfor
            return { "match": strpart(a:match, a:lastIndex, indexNew), "lastIndex": indexNew, "attr": attrNew }
        endfunction
        return ret.thenProcess
    endfunction

    function me.concat(...) closure
        let args = [0] + copy(a:000)
        return call(me.concat0, args)
    endfunction

    function me.choice(...) closure
        let args = copy(a:000)
        let ret = {}
        function! ret.choiceProcess(match, lastIndex, attr) closure
            for Arg in args
                let result = Arg(a:match, a:lastIndex, a:attr)
                if result isnot 0
                    return result
                endif
            endfor
            return 0
        endfunction
        return ret.choiceProcess
    endfunction

    function me.times(mincount, maxcount, exp) closure
        let Exp = a:exp
        let ret = {}
        function! ret.timesProcess(match, lastIndex, attr) closure
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
                        return { "match": matched, "lastIndex": indexNew, "attr": attrNew }
                    endif
                else
                    let indexNew = me.ignore(a:match, result["lastIndex"])
                    let matched = strpart(a:match, a:lastIndex, indexNew)
                    let attrNew = result["attr"]
                    let i = i + 1
                endif
            endwhile
            return { "match": matched, "lastIndex": indexNew, "attr": attrNew }
        endfunction
        return ret.timesProcess
    endfunction

    function me.oneOrMore(Exp) closure
        return me.times(1, 0, a:Exp)
    endfunction

    function me.zeroOrMore(Exp) closure
        return me.times(0, 0, a:Exp)
    endfunction

    function me.opt(Exp) closure
        return me.times(0, 1, a:Exp)
    endfunction

    function me.lookahead(Exp) closure
        return me.lookaheadNot(me.lookaheadNot(a:Exp))
    endfunction

    function me.lookaheadNot(Exp) closure
        let Exp = a:Exp
        let ret = {}
        function! ret.lookaheadProcess(match, lastIndex, attr) closure
            let result = Exp(a:match, a:lastIndex, a:attr)
            if result is 0
                return { "match": "", "lastIndex": a:lastIndex, "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return ret.lookaheadProcess
    endfunction

    function me.isEnd() closure
        let ret = {}
        function ret.isEndProcess(match, lastIndex, attr) closure
            if a:lastIndex >= len(a:match)
                return { "match": "", "lastIndex": a:lastIndex, "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return ret.isEndProcess
    endfunction

    function me.action(Exp, Action) closure
        let Exp = a:Exp
        let Action = a:Action
        let ret = {}
        function! ret.actionProcess(match, lastIndex, attr) closure
            let result = Exp(a:match, a:lastIndex, a:attr)
            if result is 0
                return 0
            else
                let retval = copy(result)
                let retval["attr"] = Action(retval["match"], retval["attr"], a:attr)
                return retval
            endif
        endfunction
        return ret.actionProcess
    endfunction

    function me.key(key) closure
        let checkkeys = []
        for x in keys
            if len(x) > len(a:key)
                call add(checkkeys, me.lookaheadNot(me.str(x)))
            endif
        endfor
        return me.concat(call(me.concat, checkkeys), me.str(a:key))
    endfunction

    function me.notKey() closure
        let checkkeys = []
        for x in keys
            call add(checkkeys, me.lookaheadNot(me.str(x)))
        endfor
        return call(me.concat, checkkeys)
    endfunction

    function me.equalsId(key) closure
        if Ignore is 0 && keys is 0
            return me.str(a:key)
        elseif !(Ignore is 0) && keys is 0
            return me.concat0(0, me.str(a:key), me.choice(me.isEnd(), me.lookahead(Ignore)))
        elseif Ignore is 0 && !(keys is 0)
            return me.concat0(0, me.str(a:key), me.choice(me.isEnd(), me.lookaheadNot(me.notKey())))
        else
            return me.concat0(0, me.str(a:key), me.choice(me.isEnd(), me.lookahead(Ignore), me.lookaheadNot(me.notKey())))
        endif
    endfunction

    function me.attr(attr) closure
        let attrNew = a:attr
        let ret = {}
        function! ret.attrProcess(match, lastIndex, attr) closure
            return { "match": "", "lastIndex": a:lastIndex, "attr": attrNew }
        endfunction
        return ret.attrProcess
    endfunction

    function me.cond(Pred) closure
        let Pred = a:Pred
        let ret = {}
        function! ret.condProcess(match, lastIndex, attr) closure
            if Pred(a:attr)
                return { "match": "", "lastIndex": a:lastIndex, "attr": a:attr }
            else
                return 0
            endif
        endfunction
        return ret.condProcess
    endfunction

    function me.real() closure
        return me.action(me.re(realRegex), { match, syn, inh -> str2float(match) })
    endfunction

    function me.letrec(...) closure
        let args = copy(a:000)
        let delays = []
        let memo = []
        let inner = {}
        function inner.memorize(index, match, lastIndex, attr) closure
            if memo[a:index] is 0
                let memo[a:index] = call(args[a:index], delays)
            endif
            let ToCall = memo[a:index]
            return ToCall(a:match, a:lastIndex, a:attr)
        endfunction
        function inner.passindex(index) closure
            call add(delays, {match, lastIndex, attr -> inner.memorize(a:index, match, lastIndex, attr)})
        endfunction
        for i in range(len(args))
            call inner.passindex(i)
            call add(memo, 0)
        endfor
        return delays[0]
    endfunction

    return me
endfunction

