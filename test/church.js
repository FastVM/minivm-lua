
const zero = () => x => x;
const succ = c => f => x => f(c(f)(x));
const exp = (c, e) => e(c);
const tochurch = n => n === 0 ? zero : succ(tochurch(n-1));
const tojs = (c) => c(x => x + 1)(0);

console.log(tojs(exp(tochurch(2), tochurch(24))));
