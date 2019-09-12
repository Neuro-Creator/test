import math
import smtplib
import sys
from functools import reduce


def cathetus(hypo, cath):
    return math.sqrt(hypo**2 - cath**2)

def vmin(r, s):
    return cathetus(s+r, 1) - cathetus(s-r, 1)


def vmax(r, s):
    return 2 * (cathetus(s, 1-r) - cathetus(s, 1+r))


def rad2degree(a):
    return 180*a/math.pi


def aux916(n):
    def multiplist(sr, m):
        adder = 0
        result = []
        for s in reversed(sr):
            tmp = int(s) * m + adder
            digit = int(tmp % 10)
            adder = int((tmp - digit) / 10)
            result.append(str(digit))
        else:
            if adder > 0:
                result += list(str(adder)[::-1])
        return list(reversed(result))
    res = ['1']
    for x in range(1, n+1):
        res = multiplist(res, 2)
    return sum(map(lambda x: int(x), res))


def aux956():
    """import operator"""
    def trilist_range(start, stop):
        for p in range(start, stop):
            for a in range(1, math.floor(p/2)):
                b = (p**2 - 2*p*a)/(2*(p-a))
                if math.ceil(b) == math.floor(b):
                    b = int(b)
                    if (p - b - a)**2 == a**2 + b**2:
                        yield [p, a, b, (p - b - a)]
    d = {}
    for x in trilist_range(10, 1001):
        try:
            d[x[0]] += 1
        except KeyError:
            d[x[0]] = 1
    return max(d.items(), key=operator.itemgetter(1))


def aux739():
    r_max, i_max = 0, 0
    with open('aux_739.txt', 'rt') as fd:
        for i, line in enumerate(fd):
            x, p = map(lambda s: int(s), line.rstrip('\n').split(','))
            res = p*math.log(x)
            if res > r_max:
                r_max, i_max = res, i
    return i_max + 1


def aux345(start, stop):
    def filter345(x):
        pattern = '1234567890'
        s = ''.join(map(lambda y: y[1], filter(lambda x: x[0]%2 == 0, enumerate(str(x)))))
        if s == pattern:
            return True
        return False
    a_tmp = math.floor(math.sqrt(start))
    a = a_tmp - a_tmp%10
    b = math.ceil(math.sqrt(stop))
    for x in range(a,b,10):
        if filter206(x**2):
            return x
    return 0





