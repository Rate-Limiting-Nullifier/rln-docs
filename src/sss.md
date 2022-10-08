# Shamir's Secret Sharing Scheme

*This topic is an explanation of **Shamir's Secret Sharing** scheme (**SSS**) also known as \\((k, n)\\) threshold secret sharing scheme. **SSS** is one of the key parts of **RLN** due to which we can share and restore the secret.*

## Overview
Imagine, if you have some important secret (secret key) and you don't want to store it anywhere. For that you can use *SSS* scheme. It allows you to split this secret into \\(n\\) parts (each individual part doesn't give any information about the secret) and restore this secret upon presentation of \\(k\\) \\((k <= n)\\) parts.

For example, you have a secret and you want to split it into \\(n\\) parts/shares. You can divide these shares between your friends (1 share to 1 friend). Now when \\(k\\) of your friends reveal their share you can restore the secret.

This scheme is also called \\((k, n)\\) *threshold secret sharing scheme*.

This scheme is possible due to *polynomial interpolation* (especially Lagrange interpolation). Let's describe how *Lagrange interpolation* works and then how it's used in *SSS* scheme.

## Polynomial (Lagrange) interpolation

*Interpolation* is a method of constructing (or restoring) new points/values (or function) based on the range of a set of known points/values (f.e. we can restore the line (linear function) from two points, that are from this line). Previous example actually describes how that works. 
<p align="center">
    <img src="./images/graph1.png" width="300">
</p>
<p align="center">
    <i>An unlimited number of parabolas (second degree polynomials) can be drawn through two points. To choose the only one, you need a third point.</i>
</p>

Thus, if we have a polynomial \\(f(x) = 3x + 2\\) we only need two points from this polynomial to restore it. Let's peek two random \\(x\\) values and calculate \\(f(x)\\):
* For \\(x = 1\\) we have \\(f(1) = 3 * 1 + 2 = 5\\)
* For \\(x = 10\\) we have \\(f(10) = 32\\)

Now we have to shares: \\((1, 5)\\) and \\((10, 32)\\). If we draw a graph based on these two shares, we can easily see that this is the same line (function):
<p align="center">
    <img src="./images/line.png" width="500" height="400">
</p>

We also can "restore" the function analytically. For that let's denote: \\[f(x) = y_1 * \frac{x - x_2}{x_1 - x_2} + y_2 * \frac{x - x_1}{x_2 - x_1}\\]
where \\(x_1 = 5, x_2 = 10, y_1 = 5, y_2 = 32\\). If we make substitution we got: \\[f(x) = 3x + 2 \\]
which is the same polynomial.

The same techique can be made with every polynomial. Main thing to remember is that we need \\(n + 1\\) points to interpolate \\(n\\)-degree polynomial.

Now that we know how interpolation works, we can learn how it is used in SSS.

## Shamir's Secret Sharing
