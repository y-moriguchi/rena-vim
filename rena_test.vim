"
" This source code is under the Unlicense.
"
function! s:ok(Exp, string, match, lastIndex)
    let result = a:Exp(a:string, 0, 0)
    if result is 0
        call assert_equal(1, 2)
    else
        call assert_equal(a:match, result["match"])
        call assert_equal(a:lastIndex, result["lastIndex"])
    endif
endfunction

function! s:ng(Exp, string)
    let result = a:Exp(a:string, 0, 0)
    if result is 0
    else
        call assert_equal(1, 2)
    endif
endfunction

function! s:okattr(Exp, string, match, lastIndex, attr)
    let result = a:Exp(a:string, 0, 27)
    if result is 0
        call assert_equal(1, 2)
    else
        call assert_equal(a:match, result["match"])
        call assert_equal(a:lastIndex, result["lastIndex"])
        call assert_equal(a:attr, result["attr"])
    endif
endfunction

function! s:assertReal(string, attr)
    let r = Rena()
    let Exp = r.real()
    let result = Exp(a:string, 0, 0)
    if result is 0
        call assert_equal(1, 2)
    else
        call assert_equal(a:attr, result["attr"])
    endif
endfunction

function! RenaTest()
    let r = Rena()
    let v:errors = []

    " simple str
    call s:ok(r.str("765"), "765pro", "765", 3)
    call s:ng(r.str("765"), "961pro")
    call s:ng(r.str("765"), "")

    " simple regex
    call s:ok(r.re("a\\+"), "aaaab", "aaaa", 4)
    call s:ng(r.re("a\\+"), "b")

    " concat
    call s:ok(r.concat(r.str("765"), r.str("pro")), "765pro", "765pro", 6)
    call s:ng(r.concat(r.str("765"), r.str("pro")), "961pro")
    call s:ng(r.concat(r.str("765"), r.str("pro")), "765aaa")
    call s:ng(r.concat(r.str("765"), r.str("pro")), "")
    call s:ok(r.concat(r.str("765"), r.re("[0-9]\\+")), "765346", "765346", 6)
    call s:ng(r.concat(r.str("765"), r.re("[0-9]\\+")), "765aaa")

    " choice
    call s:ok(r.choice(r.str("765"), r.str("346"), r.str("283")), "765", "765", 3)
    call s:ok(r.choice(r.str("765"), r.str("346"), r.str("283")), "346", "346", 3)
    call s:ok(r.choice(r.str("765"), r.str("346"), r.str("283")), "283", "283", 3)
    call s:ng(r.choice(r.str("765"), r.str("346"), r.str("283")), "961")

    " oneOrMOre
    call s:ok(r.oneOrMore(r.str("a")), "aaaa", "aaaa", 4)
    call s:ok(r.oneOrMore(r.str("a")), "a", "a", 1)
    call s:ng(r.oneOrMore(r.str("a")), "")

    " zeroOrMore
    call s:ok(r.zeroOrMore(r.str("a")), "aaaa", "aaaa", 4)
    call s:ok(r.zeroOrMore(r.str("a")), "a", "a", 1)
    call s:ok(r.zeroOrMore(r.str("a")), "", "", 0)

    " opt
    call s:ok(r.opt(r.str("a")), "aaaa", "a", 1)
    call s:ok(r.opt(r.str("a")), "a", "a", 1)
    call s:ok(r.opt(r.str("a")), "", "", 0)

    " lookaheadNot
    call s:ok(r.lookaheadNot(r.str("961")), "765", "", 0)
    call s:ng(r.lookaheadNot(r.str("961")), "961")

    " lookahead
    call s:ok(r.lookahead(r.str("765")), "765", "", 0)
    call s:ng(r.lookahead(r.str("765")), "961")

    " isEnd
    call s:ok(r.concat(r.str("765"), r.isEnd()), "765", "765", 3)
    call s:ng(r.concat(r.str("765"), r.isEnd()), "765aaa")

    " action
    call s:okattr(r.action(r.re("[a-z]\\+"), { match, syn, inh -> len(match) + inh }), "aaa", "aaa", 3, 30)
    call s:okattr(r.action(r.real(), { match, syn, inh -> syn + inh }), "72", "72", 2, 99.0)
    call s:ng(r.action(r.re("[a-z]\\+"), { match, syn, inh -> len(match) + inh }), "")

    " key
    let r1 = Rena({ "keys": ["+", "++", "-"] })
    call s:ok(r1.key("+"), "+", "+", 1)
    call s:ng(r1.key("+"), "++")

    " notKey
    call s:ok(r1.notKey(), "/", "", 0)
    call s:ng(r1.notKey(), "+")
    call s:ng(r1.notKey(), "++")
    call s:ng(r1.notKey(), "-")

    " equalsId
    let r2 = Rena({ "ignore": r.re("[ \\t]\\+") })
    let r3 = Rena({ "ignore": r.re("[ \\t]\\+"), "keys": ["+", "++", "-"] })
    call s:ok(r.equalsId("key"), "key", "key", 3)
    call s:ok(r.equalsId("key"), "key  ", "key", 3)
    call s:ok(r.equalsId("key"), "key+", "key", 3)
    call s:ok(r.equalsId("key"), "key", "key", 3)
    call s:ok(r1.equalsId("key"), "key", "key", 3)
    call s:ng(r1.equalsId("key"), "key  ")
    call s:ok(r1.equalsId("key"), "key+", "key", 3)
    call s:ng(r1.equalsId("key"), "keys")
    call s:ok(r2.equalsId("key"), "key", "key", 3)
    call s:ok(r2.equalsId("key"), "key  ", "key", 3)
    call s:ng(r2.equalsId("key"), "key+")
    call s:ng(r2.equalsId("key"), "keys")
    call s:ok(r3.equalsId("key"), "key", "key", 3)
    call s:ok(r3.equalsId("key"), "key  ", "key", 3)
    call s:ok(r3.equalsId("key"), "key+", "key", 3)
    call s:ng(r3.equalsId("key"), "keys")

    " attr
    call s:okattr(r.attr(72), "", "", 0, 72)

    " cond
    call s:ok(r.cond({ attr -> attr == 0 }), "", "", 0)
    call s:ng(r.cond({ attr -> attr < 0 }), "")

    " real
    call s:assertReal("765", 765.0)
    call s:assertReal("76.5", 76.5)
    call s:assertReal("0.765", 0.765)
    call s:assertReal(".765", 0.765)
    call s:assertReal("765e2", 76500.0)
    call s:assertReal("765E2", 76500.0)
    call s:assertReal("765e+2", 76500.0)
    call s:assertReal("765e-2", 7.65)
    " call s:assertReal("765e+346", Infinity)
    call s:assertReal("765e-346", 0.0)
    call s:ng(r.real(), "a961")
    call s:assertReal("+765", 765.0)
    call s:assertReal("+76.5", 76.5)
    call s:assertReal("+0.765", 0.765)
    call s:assertReal("+.765", 0.765)
    call s:assertReal("+765e2", 76500.0)
    call s:assertReal("+765E2", 76500.0)
    call s:assertReal("+765e+2", 76500.0)
    call s:assertReal("+765e-2", 7.65)
    " call s:assertReal("+765e+346", Infinity)
    call s:assertReal("+765e-346", 0.0)
    call s:ng(r.real(), "+a961")
    call s:assertReal("-765", -765.0)
    call s:assertReal("-76.5", -76.5)
    call s:assertReal("-0.765", -0.765)
    call s:assertReal("-.765", -0.765)
    call s:assertReal("-765e2", -76500.0)
    call s:assertReal("-765E2", -76500.0)
    call s:assertReal("-765e+2", -76500.0)
    call s:assertReal("-765e-2", -7.65)
    " call s:assertReal("-765e+346", -Infinity)
    call s:assertReal("-765e-346", 0.0)
    call s:ng(r.real(), "-a961")

    " letrec
    let A = r.letrec({ x -> r.concat(r.str("("), r.opt(x), r.str(")")) })
    let B = r.letrec({ x, y -> r.concat(r.str("("), r.opt(y), r.str(")")) }, { x, y -> r.concat(r.str("["), r.opt(x), r.str("]")) })
    call s:ok(A, "((()))", "((()))", 6)
    call s:ok(A, "((())))", "((()))", 6)
    call s:ng(A, "((())")
    call s:ok(B, "([([])])", "([([])])", 8)
    call s:ok(B, "([([])])]", "([([])])", 8)
    call s:ng(B, "([([])]")

    echo v:errors
endfunction

