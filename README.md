# Scheme Compiler in OCaml

**Authors:**
Ori Adika
Dolev David

## 🔧 Description

This project is a full compiler from a subset of the Scheme programming language to x86-64 assembly, written entirely in OCaml. It was built as part of a university course on compiler design and includes all key compiler stages:

- **S-expression Reader** (`read`)
- **Parser (Tag Parser)** — from S-expressions to AST (`expr`)
- **Semantic Analyzer** — variable scoping, boxing, and tail-call annotations (`expr'`)
- **Code Generator** — emits assembly code in NASM syntax
- **Support for built-in primitives and runtime (`init.scm`, `epilogue.asm`)**

The project includes full support for lexical scoping, closures, macro expansion, lambda expressions, `let`, `let*`, `letrec`, `cond`, `quasiquote`, and more.

## 📂 Project Structure

```
compiler/
├── compiler.ml        # Combined compiler logic (parsing, semantics, codegen)
├── pc.ml              # Primitive definitions and constants
├── prologue-1.asm     # Runtime memory and symbol setup (part 1)
├── prologue-2.asm     # Runtime constants setup (part 2)
├── epilogue.asm       # Built-in procedure implementations, including `apply`
├── init.scm           # Bootstrapping runtime definitions in Scheme
├── makefile           # Automates build process into final executable
├── README.md          # This file
```

## 🚀 How to Run

### ✅ Prerequisites

- [OCaml](https://ocaml.org/) installed (tested with OCaml 4.14+)
- Terminal with UTF-8 support (e.g. macOS Terminal or Linux shell)

### 🧪 Interactive Use in `utop`

Launch OCaml and load the compiler:

```bash
ocaml
#use "compiler.ml";;
```

Once loaded, you can use the following functions interactively:

- `read : string -> sexpr` — parses a raw Scheme string into an S-expression
- `parse : string -> expr` — converts S-expression into a Scheme AST
- `sem : string -> expr'` — performs semantic analysis (variable resolution, tail-call marking, boxing)
- `test : string -> unit` — compiles the input Scheme string and emits `goo.asm` with the corresponding x86-64 code

## 💡 Examples

```ocaml
# read "(+ 1 2)";;
- : sexpr = Pair (Symbol "+", Pair (Number (Int 1), Pair (Number (Int 2), Nil)))

# parse "(define x 3)";;
- : expr = ScmVarDef (Var "x", ScmConst (ScmNumber (ScmInteger 3)))

# sem "(lambda (x) (lambda (y) (+ x y)))";;
- : expr' =
  ScmLambda'(["x"], Simple,
    ScmLambda'(["y"], Simple,
      ScmApplic'(ScmVarGet'(Var'("+", Free)),
        [ScmVarGet'(Var'("x", Bound(0, 0))); ScmVarGet'(Var'("y", Param 0))],
        Tail_Call)))

# test "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1))))) (fact 5)";;
# => generates compiled assembly in goo.asm and return the output in the CLI.
```

## 🎓 Educational Value

This project combines multiple core compiler concepts:

- Abstract syntax trees and macro transformation
- Lexical scoping and variable resolution (Free, Bound, Param)
- Tail call optimization and continuation marking
- Closure creation and boxing logic for mutable bindings
- Full-stack understanding from Scheme syntax to machine-level output

## 📜 License

This project is released under the MIT License.

---

> For questions, academic use, or collaborations — feel free to contact us.
