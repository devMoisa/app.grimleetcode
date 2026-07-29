import Foundation

/// Ergonomic builders so the full 16-module Python roadmap fits in one readable file.
enum RoadmapBuilder {
    static func lesson(
        _ id: String,
        _ title: String,
        summary: String,
        theory: String = "",
        exercises: [Problem] = []
    ) -> Lesson {
        Lesson(
            id: uuid(id),
            title: title,
            summary: summary,
            theory: theory,
            exercises: exercises
        )
    }

    static func module(_ id: String, _ title: String, summary: String, lessons: [Lesson]) -> Module {
        Module(id: uuid(id), title: title, summary: summary, lessons: lessons)
    }

    static func exercise(
        _ id: String,
        _ title: String,
        statement: String,
        examples: [Problem.Example] = [],
        constraints: [String] = []
    ) -> Problem {
        Problem(
            id: uuid(id),
            title: title,
            difficulty: .easy,
            tags: [],
            statement: statement,
            examples: examples,
            constraints: constraints,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    /// Deterministic UUID from an ASCII slug so lesson/exercise IDs are stable across launches.
    static func uuid(_ slug: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (i, byte) in slug.utf8.enumerated() where i < 16 {
            bytes[i] = byte
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

// MARK: - Python 0 → Hero

enum PythonRoadmap {
    static let track: Track = Track(
        id: RoadmapBuilder.uuid("track-python"),
        language: .python,
        title: "Python: 0 → Hero",
        subtitle: "From your first print to metaclasses, async and profiling. 16 modules.",
        modules: [
            fundamentals,
            controlFlow,
            collections,
            functions,
            modulesAndPackages,
            fileIO,
            oop,
            errorHandling,
            iteratorsAndGenerators,
            concurrency,
            testingAndDebugging,
            dataStructuresAndAlgorithms,
            typingAndModern,
            standardLibraryDeepDive,
            practicalSkills,
            advancedTopics,
        ]
    )

    // MARK: - Module 1 (FULLY DETAILED — proof of complete UX)

    private static let fundamentals = RoadmapBuilder.module(
        "mod-1-fundamentals",
        "Fundamentals",
        summary: "Setup, the REPL, primitive types, operators and reading input. If you've never written Python, start here.",
        lessons: [
            RoadmapBuilder.lesson(
                "l-setup",
                "Setting up Python",
                summary: "Install Python, run the REPL, and understand the difference between REPL and scripts.",
                theory: """
                Python is an interpreted language. You have **two ways** to run code:

                - **REPL** (Read-Eval-Print Loop): open a terminal and type `python3`. You get a `>>>` prompt where each line runs immediately.
                - **Script**: write code in a `.py` file and run it with `python3 file.py`.

                The REPL is perfect for exploration; scripts are what you actually ship.

                ## Verify your install

                Open a terminal and run:

                ```bash
                python3 --version
                ```

                You should see something like `Python 3.12.x`. If not, install from [python.org](https://www.python.org/downloads/) or via `brew install python`.

                ## Virtual environments (preview)

                Real projects isolate their dependencies in **virtual environments** (venv) so packages don't clash across projects. You'll see this in the *Modules & Packages* module.
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-setup-hello",
                        "Print your first line",
                        statement: """
                        Write a Python program that prints the exact string:

                        ```
                        Hello, Roadmap!
                        ```

                        No leading/trailing spaces, followed by a newline.
                        """,
                        examples: [
                            .init(input: "(no input)", output: "Hello, Roadmap!", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-firstprogram",
                "Your first program",
                summary: "print(), comments, and how execution flows top to bottom.",
                theory: """
                Every Python program executes **top to bottom**. Lines are statements, and blank lines are ignored.

                ## `print()` — writing to stdout

                ```python
                print("Hello!")           # single string
                print("Sum:", 2 + 3)      # multiple args, space-separated
                print("a", "b", sep="-")  # custom separator → a-b
                print("no newline", end="")
                ```

                Everything you `print` goes to **stdout** — the same channel your terminal reads.

                ## Comments

                - `#` starts a line comment
                - Triple-quoted strings that aren't assigned to anything are effectively multiline comments (though technically they're just unused string literals)

                ```python
                # This is a comment.
                x = 5  # inline comment

                \"\"\"
                Docstring-style block, often used at the top of modules,
                classes, and functions to document them.
                \"\"\"
                ```

                Comments are for **humans**, not the interpreter — write them to explain *why*, not *what*.
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-firstprogram-print",
                        "Print your name three ways",
                        statement: """
                        Print the following exactly three lines:

                        1. Your name in a single call.
                        2. `Name: <your name>` using two `print` arguments (separated by a space).
                        3. Your name split by `-` between letters using the `sep` parameter of `print`.

                        Example if your name is `Ada`:

                        ```
                        Ada
                        Name: Ada
                        A-d-a
                        ```
                        """,
                        examples: [
                            .init(input: "(name is Ada)", output: "Ada\nName: Ada\nA-d-a", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-variables",
                "Variables and naming",
                summary: "Assignment, dynamic typing, and Python's naming conventions.",
                theory: """
                Python variables are **names bound to values**. There's no type declaration — the type comes from the value.

                ```python
                age = 30              # int
                pi = 3.14             # float
                name = "Ada"          # str
                is_active = True      # bool
                nothing = None        # NoneType
                ```

                ## Reassigning changes the type freely

                ```python
                x = 10        # x is int
                x = "ten"     # now x is str — Python doesn't care
                ```

                This is **dynamic typing**. It's fast to write but requires discipline.

                ## Naming rules and conventions

                - Names must start with a letter or `_`, followed by letters/digits/`_`.
                - Case-sensitive: `age` and `Age` are different.
                - **PEP 8 style**: `snake_case` for variables and functions, `PascalCase` for classes, `UPPER_SNAKE` for constants.

                ```python
                first_name = "Ada"       # snake_case
                MAX_RETRIES = 5          # constant
                class UserProfile: ...   # PascalCase
                ```

                ## Multiple assignment

                ```python
                a, b, c = 1, 2, 3        # unpacking
                x = y = z = 0            # chained
                ```
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-variables-swap",
                        "Swap two values",
                        statement: """
                        Read two integers from stdin, one per line. Print them **swapped** on two lines: the second value first, then the first.

                        Do it using Python's tuple-unpacking swap idiom (`a, b = b, a`) — no temporary variable.
                        """,
                        examples: [
                            .init(input: "10\n20", output: "20\n10", explanation: nil),
                            .init(input: "7\n3", output: "3\n7", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-primitives",
                "Primitive types",
                summary: "int, float, bool, None — and how they interact.",
                theory: """
                Python's built-in scalar types:

                | Type | Example | Notes |
                |------|---------|-------|
                | `int` | `42`, `-7`, `0` | Arbitrary precision. No overflow. |
                | `float` | `3.14`, `1e-9` | IEEE-754 double. Beware precision. |
                | `bool` | `True`, `False` | Subclass of `int` — `True == 1`, `False == 0`. |
                | `NoneType` | `None` | The sole "absence" value. Use `is None`, not `== None`. |

                ## Arithmetic

                ```python
                7 / 2      # 3.5   — always float
                7 // 2     # 3     — floor division
                7 % 2      # 1     — modulo
                2 ** 10    # 1024  — power
                ```

                ## Truthiness

                Every value is either **truthy** or **falsy**:

                - Falsy: `False`, `None`, `0`, `0.0`, `""`, `[]`, `{}`, `set()`
                - Everything else is truthy

                ```python
                if name:            # runs if name is non-empty
                    print(name)
                ```
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-primitives-avg",
                        "Integer average, rounded",
                        statement: """
                        Read three integers from stdin (one per line). Compute their **true average** as a float and print it **rounded to two decimal places**.

                        Hint: use `round(x, 2)` or f-string formatting `f"{x:.2f}"`.
                        """,
                        examples: [
                            .init(input: "1\n2\n3", output: "2.00", explanation: nil),
                            .init(input: "10\n15\n11", output: "12.00", explanation: nil),
                            .init(input: "1\n2\n4", output: "2.33", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-strings-basics",
                "Strings — the basics",
                summary: "Creating strings, escape sequences, raw strings, concatenation.",
                theory: """
                Strings in Python are **immutable sequences of Unicode characters**.

                ## Quoting

                ```python
                a = 'single'
                b = "double"
                c = '''triple'''            # multiline OK
                d = \"\"\"another triple\"\"\"
                ```

                All four are the same type (`str`). Use whichever avoids escaping.

                ## Escape sequences

                | Escape | Meaning |
                |--------|---------|
                | `\\n` | newline |
                | `\\t` | tab |
                | `\\\\` | literal backslash |
                | `\\'` | literal single quote |
                | `\\"` | literal double quote |

                ## Raw strings

                Prefix with `r` to disable escapes — great for regex and paths:

                ```python
                path = r"C:\\Users\\Ada\\file.txt"
                ```

                ## Concatenation and repetition

                ```python
                "foo" + "bar"     # "foobar"
                "ha" * 3          # "hahaha"
                ```

                Repeated `+` is slow for many strings — use `"".join([...])` instead.
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-strings-echo",
                        "Echo a name in three formats",
                        statement: """
                        Read a name from stdin (a single line). Print three lines:

                        1. The name uppercased.
                        2. The name reversed.
                        3. The name repeated three times separated by ` | `.

                        Example: input `Ada`, output:
                        ```
                        ADA
                        adA
                        Ada | Ada | Ada
                        ```
                        """,
                        examples: [
                            .init(input: "Ada", output: "ADA\nadA\nAda | Ada | Ada", explanation: nil),
                            .init(input: "moi", output: "MOI\niom\nmoi | moi | moi", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-strings-format",
                "String formatting",
                summary: "f-strings (modern), .format() (legacy), and % (historical).",
                theory: """
                Three ways to interpolate values into strings. **Prefer f-strings** in new code (Python 3.6+).

                ## f-strings (recommended)

                ```python
                name, age = "Ada", 30
                greeting = f"Hi {name}, you are {age} years old."
                ```

                Expressions inside `{ }` are evaluated:

                ```python
                f"{2 + 3}"            # "5"
                f"{name.upper()}"     # "ADA"
                f"{price:.2f}"        # "3.14"    ← format spec
                f"{value:>10}"        # right-align width 10
                f"{count:05d}"        # zero-pad → "00042"
                f"{data=}"            # "data=..."  ← debug format (3.8+)
                ```

                ## Format specifiers cheat sheet

                | Spec | Meaning |
                |------|---------|
                | `.2f` | 2 decimals |
                | `>10` | right-align, width 10 |
                | `<10` | left-align, width 10 |
                | `^10` | center, width 10 |
                | `05d` | zero-padded int, width 5 |
                | `,` | thousands separator |
                | `%` | percent |

                ```python
                f"{1234567:,}"        # "1,234,567"
                f"{0.87:.1%}"          # "87.0%"
                ```
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-format-receipt",
                        "Receipt formatter",
                        statement: """
                        Read three lines from stdin: an item name (string), a quantity (int), a unit price (float). Print a single line in this exact format:

                        ```
                        <name> x <quantity> @ $<unit_price to 2 decimals> = $<total to 2 decimals>
                        ```

                        Example: `Coffee`, `3`, `4.5` → `Coffee x 3 @ $4.50 = $13.50`.
                        """,
                        examples: [
                            .init(input: "Coffee\n3\n4.5", output: "Coffee x 3 @ $4.50 = $13.50", explanation: nil),
                            .init(input: "Bagel\n2\n2.75", output: "Bagel x 2 @ $2.75 = $5.50", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-typeconv",
                "Type conversion",
                summary: "int(), float(), str(), bool() and when Python converts implicitly.",
                theory: """
                Python is **dynamically typed** but **strongly typed** — it doesn't secretly convert types across operators (unlike JavaScript). You do it explicitly.

                ```python
                int("42")         # 42
                int("42.7")       # ValueError!  int() from str won't parse floats
                int(42.7)         # 42           truncates toward zero
                float("3.14")     # 3.14
                str(3.14)         # "3.14"
                bool(0), bool(""), bool([])   # all False
                bool(1), bool("x"), bool([0]) # all True
                ```

                ## Reading input

                `input()` **always returns a string**. Convert explicitly:

                ```python
                age = int(input("Age: "))
                temp = float(input("Temp: "))
                ```

                ## Watch out for float precision

                ```python
                0.1 + 0.2         # 0.30000000000000004 — welcome to floats
                round(0.1 + 0.2, 1)  # 0.3
                ```

                For money and other exact decimals, use the `decimal` module.
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-typeconv-sum",
                        "Sum two typed inputs",
                        statement: """
                        Read two lines from stdin. The first is an integer, the second is a float. Print their **sum as a float rounded to two decimals**.
                        """,
                        examples: [
                            .init(input: "5\n2.5", output: "7.50", explanation: nil),
                            .init(input: "0\n0.1", output: "0.10", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-operators",
                "Operators",
                summary: "Arithmetic, comparison, logical, bitwise, membership, identity.",
                theory: """
                ## Arithmetic

                `+  -  *  /  //  %  **`

                ## Comparison

                `==  !=  <  >  <=  >=`  → always return `bool`

                Comparisons **chain**:

                ```python
                if 0 <= age < 120:    # equivalent to (0 <= age) and (age < 120)
                    ...
                ```

                ## Logical

                `and`, `or`, `not` — short-circuit and return one of the operands (not always `True`/`False`):

                ```python
                x = a or b            # a if truthy, else b
                y = a and b           # b if a is truthy, else a
                ```

                ## Membership

                ```python
                "a" in "abc"          # True
                3 in [1, 2, 3]        # True
                "key" in {"key": 1}   # True
                ```

                ## Identity

                `is` and `is not` check **same object**, not equality:

                ```python
                x = [1, 2]
                y = [1, 2]
                x == y                # True — equal contents
                x is y                # False — different objects
                x is None             # correct way to check for None
                ```

                ## Bitwise (rare in day-to-day)

                `&` `|` `^` `~` `<<` `>>`
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-operators-inrange",
                        "In-range check",
                        statement: """
                        Read three integers from stdin: `low`, `high`, `x` (one per line). Print `yes` if `low <= x <= high`, otherwise print `no`. Use chained comparison.
                        """,
                        examples: [
                            .init(input: "1\n10\n5", output: "yes", explanation: nil),
                            .init(input: "1\n10\n11", output: "no", explanation: nil),
                            .init(input: "0\n0\n0", output: "yes", explanation: nil)
                        ]
                    )
                ]
            ),
            RoadmapBuilder.lesson(
                "l-input",
                "Reading input from the user",
                summary: "input() basics, reading multiple lines, sys.stdin for bulk.",
                theory: """
                ## `input()`

                Reads a single line from stdin **without** the trailing newline. Always returns `str`.

                ```python
                name = input("What's your name? ")
                age = int(input("Age: "))
                ```

                ## Reading multiple lines

                Call `input()` multiple times, or split on whitespace:

                ```python
                a, b = input().split()          # "1 2" → a="1", b="2"
                nums = list(map(int, input().split()))
                ```

                ## Reading a whole stream (competitive style)

                For lots of input, `sys.stdin` is faster:

                ```python
                import sys
                data = sys.stdin.read().split()
                ```

                ## In this app

                Every exercise in the Roadmap reads from **stdin** and writes to **stdout** — the sandbox runner captures both.
                """,
                exercises: [
                    RoadmapBuilder.exercise(
                        "ex-input-name-and-age",
                        "Greet with name and age",
                        statement: """
                        Read two lines from stdin: a name (string) and an age (int). Print exactly:

                        ```
                        Hello <name>, in 10 years you will be <age+10>.
                        ```
                        """,
                        examples: [
                            .init(input: "Ada\n30", output: "Hello Ada, in 10 years you will be 40.", explanation: nil),
                            .init(input: "Bob\n7", output: "Hello Bob, in 10 years you will be 17.", explanation: nil)
                        ]
                    )
                ]
            ),
        ]
    )

    // MARK: - Modules 2 – 16 (structure + summaries; content generated later)

    private static let controlFlow = RoadmapBuilder.module(
        "mod-2-control", "Control Flow",
        summary: "Branches, loops, and pattern matching. The shapes your programs take.",
        lessons: [
            stubLesson("l-if", "Conditionals (if / elif / else)", "Branching on truthiness, ternary expressions."),
            stubLesson("l-while", "while loops", "Looping until a condition changes; sentinel loops."),
            stubLesson("l-for", "for loops and range", "Iterating over sequences, `range(start, stop, step)`."),
            stubLesson("l-break-continue", "break, continue, else", "Escape hatches and the loop `else` clause."),
            stubLesson("l-match", "match / case (Python 3.10+)", "Structural pattern matching with literal, class, and mapping patterns."),
        ]
    )

    private static let collections = RoadmapBuilder.module(
        "mod-3-collections", "Collections",
        summary: "Lists, tuples, sets, dicts, and comprehensions — the everyday data structures.",
        lessons: [
            stubLesson("l-list", "Lists — creation, indexing, slicing", "Mutable ordered sequences. Slice semantics."),
            stubLesson("l-list-methods", "List methods", "append, extend, insert, remove, pop, sort, reverse."),
            stubLesson("l-tuple", "Tuples", "Immutable ordered sequences. Unpacking and named tuples."),
            stubLesson("l-set", "Sets", "Unique elements. Union, intersection, difference. O(1) membership."),
            stubLesson("l-dict", "Dictionaries", "Key-value store. Common methods and iteration."),
            stubLesson("l-listcomp", "List comprehensions", "[expr for x in iter if cond] — the Pythonic map+filter."),
            stubLesson("l-dictset-comp", "Dict and set comprehensions", "{k: v for ...} and {expr for ...}."),
            stubLesson("l-enumerate-zip", "enumerate and zip", "Indexed iteration and parallel iteration idioms."),
            stubLesson("l-nested", "Nested collections", "Matrices, lists of dicts, and depth iteration."),
        ]
    )

    private static let functions = RoadmapBuilder.module(
        "mod-4-functions", "Functions",
        summary: "Defining, calling, composing. From plain functions to decorators and recursion.",
        lessons: [
            stubLesson("l-def", "Defining functions", "def, docstrings, return values, None returns."),
            stubLesson("l-args", "Arguments — positional, keyword, default", "Argument ordering rules and defaults gotchas."),
            stubLesson("l-argsvar", "*args and **kwargs", "Variadic arguments and keyword collection."),
            stubLesson("l-multireturn", "Return values and multi-return", "Returning tuples, unpacking at call site."),
            stubLesson("l-scope", "Scope and the LEGB rule", "Local, Enclosing, Global, Built-in. global vs nonlocal."),
            stubLesson("l-lambda", "Lambda functions", "Anonymous single-expression functions and their limits."),
            stubLesson("l-higherorder", "Higher-order functions", "map, filter, sorted with key, functools.reduce."),
            stubLesson("l-decorators-intro", "Decorators — introduction", "Functions that wrap functions. @decorator syntax."),
            stubLesson("l-recursion", "Recursion", "Base case, recursive case, when to prefer iteration."),
        ]
    )

    private static let modulesAndPackages = RoadmapBuilder.module(
        "mod-5-modules", "Modules & Packages",
        summary: "Splitting code across files, using the standard library, and dependency management.",
        lessons: [
            stubLesson("l-import", "Importing modules", "import, from ... import, aliases, relative imports."),
            stubLesson("l-stdlib-tour", "Standard library tour", "math, random, datetime, os, sys — the essentials."),
            stubLesson("l-yourmodule", "Creating your own module", "One file, one module. __name__ == '__main__'."),
            stubLesson("l-package", "Packages and __init__.py", "Folder-as-module. Package init and public API."),
            stubLesson("l-pip-venv", "pip and virtual environments", "python -m venv, activate, pip install, requirements.txt."),
            stubLesson("l-uv-poetry", "Modern tooling: uv / poetry", "Fast, lockfile-based dependency management."),
        ]
    )

    private static let fileIO = RoadmapBuilder.module(
        "mod-6-fileio", "File I/O and Data",
        summary: "Reading and writing files, JSON, CSV, and dates — the practical plumbing.",
        lessons: [
            stubLesson("l-openfile", "Reading and writing files", "open(), modes (r/w/a/b), reading lines."),
            stubLesson("l-pathlib", "Working with paths (pathlib)", "Path objects, joining, existence, iterating dirs."),
            stubLesson("l-csv", "CSV files", "csv.reader / csv.writer / DictReader for tabular data."),
            stubLesson("l-json", "JSON — parse and stringify", "json.loads / json.dumps and indent/sort_keys."),
            stubLesson("l-with", "Context managers (with)", "Resource management with with-statements."),
            stubLesson("l-datetime", "Dates, times, and timezones", "datetime, timedelta, ISO 8601, zoneinfo."),
        ]
    )

    private static let oop = RoadmapBuilder.module(
        "mod-7-oop", "Object-Oriented Programming",
        summary: "Classes, instances, inheritance, polymorphism, dataclasses, and the dunder protocol.",
        lessons: [
            stubLesson("l-class-basics", "Classes and objects", "class Foo: def __init__(self, ...). Instances and attributes."),
            stubLesson("l-init-self", "__init__ and self", "Constructors, self as the first argument."),
            stubLesson("l-instance-class-attr", "Instance vs class attributes", "Where state lives and shared vs per-instance data."),
            stubLesson("l-methods", "Methods — instance, class, static", "@classmethod and @staticmethod when and why."),
            stubLesson("l-encapsulation", "Encapsulation and _/__ conventions", "Name mangling and the 'we're all adults' philosophy."),
            stubLesson("l-inheritance", "Inheritance", "class Sub(Base). super().__init__ and method overrides."),
            stubLesson("l-multiple-inheritance", "Multiple inheritance and MRO", "C3 linearization and the diamond problem."),
            stubLesson("l-polymorphism", "Polymorphism and duck typing", "If it walks like a duck… favor protocols over ABCs."),
            stubLesson("l-dunder", "Magic methods (dunder)", "__str__, __repr__, __eq__, __hash__, __lt__, __iter__, __enter__."),
            stubLesson("l-properties", "Properties and setters", "@property, @x.setter, computed attributes."),
            stubLesson("l-dataclass", "Dataclasses", "@dataclass eliminates boilerplate for data-carrying classes."),
            stubLesson("l-abc", "Abstract base classes", "abc.ABC, @abstractmethod — enforcing subclass contracts."),
        ]
    )

    private static let errorHandling = RoadmapBuilder.module(
        "mod-8-errors", "Error Handling",
        summary: "Handling exceptions and raising your own. When to catch, when to let it fly.",
        lessons: [
            stubLesson("l-try-except", "try / except / else / finally", "The full exception clause anatomy."),
            stubLesson("l-raise", "Raising exceptions", "raise Exception('msg'); using stdlib exception types."),
            stubLesson("l-custom-exceptions", "Custom exception classes", "Subclassing Exception for domain errors."),
            stubLesson("l-chained", "Chained exceptions", "raise ... from ... — preserving cause chains."),
            stubLesson("l-assert", "Assertions", "assert for invariants — never for user input validation."),
        ]
    )

    private static let iteratorsAndGenerators = RoadmapBuilder.module(
        "mod-9-iters", "Iterators, Generators & Functional",
        summary: "Lazy sequences, generator expressions, closures and decorators in depth.",
        lessons: [
            stubLesson("l-iter-protocol", "Iterators and __iter__", "The iterator protocol. iter() and next()."),
            stubLesson("l-generators", "Generators and yield", "Functions that pause. yield vs return."),
            stubLesson("l-genexp", "Generator expressions", "(expr for x in iter) — memory-efficient loops."),
            stubLesson("l-itertools", "itertools essentials", "chain, cycle, groupby, islice, product, permutations."),
            stubLesson("l-functools", "functools essentials", "partial, reduce, lru_cache, wraps."),
            stubLesson("l-closures", "Closures", "Nested functions capturing enclosing scope."),
            stubLesson("l-decorators-advanced", "Decorators — advanced", "Parameterized decorators, class decorators, functools.wraps."),
        ]
    )

    private static let concurrency = RoadmapBuilder.module(
        "mod-10-concurrency", "Concurrency and Async",
        summary: "Threads, processes, and async — three flavors of doing more than one thing.",
        lessons: [
            stubLesson("l-conc-primer", "Threads vs processes vs coroutines", "When to reach for each — the GIL in one paragraph."),
            stubLesson("l-threading", "The threading module", "Thread, Lock, RLock, Event, Queue for producer/consumer."),
            stubLesson("l-multiprocessing", "The multiprocessing module", "Process, Pool, shared state, and pickling gotchas."),
            stubLesson("l-asyncio-fund", "asyncio fundamentals", "Event loop, coroutines, tasks, gather."),
            stubLesson("l-async-await", "async / await syntax", "Writing coroutines and awaiting them."),
            stubLesson("l-async-libs", "Async libraries (httpx, aiofiles)", "How to stay async all the way down."),
            stubLesson("l-concurrent-futures", "concurrent.futures", "ThreadPoolExecutor and ProcessPoolExecutor for high-level parallelism."),
        ]
    )

    private static let testingAndDebugging = RoadmapBuilder.module(
        "mod-11-testing", "Testing and Debugging",
        summary: "unittest, pytest, mocking, logging, and the Python debugger.",
        lessons: [
            stubLesson("l-assertions-tests", "Assertions and simple tests", "assert for tiny scripts; when to graduate."),
            stubLesson("l-unittest", "unittest framework", "TestCase, setUp/tearDown, assertions taxonomy."),
            stubLesson("l-pytest", "pytest basics", "Plain functions, plain asserts, discovery."),
            stubLesson("l-fixtures", "Fixtures", "@pytest.fixture for setup/teardown and dependency injection."),
            stubLesson("l-mocking", "Mocking", "unittest.mock — patching for isolation."),
            stubLesson("l-pdb", "Debugging with pdb", "Setting breakpoints, stepping, inspecting."),
            stubLesson("l-logging", "logging module", "Levels, handlers, formatters — beyond print()."),
        ]
    )

    private static let dataStructuresAndAlgorithms = RoadmapBuilder.module(
        "mod-12-dsa", "Data Structures & Algorithms Foundations",
        summary: "Big-O, arrays, hashes, linked lists, trees, graphs — the underpinnings.",
        lessons: [
            stubLesson("l-bigo", "Time and Space Complexity (Big-O)", "How to reason about performance."),
            stubLesson("l-lists-vs-arrays", "Python lists vs C arrays", "What Python's list actually is under the hood."),
            stubLesson("l-hash-complexity", "Hash maps / dicts complexity", "O(1) amortized: why, and when it isn't."),
            stubLesson("l-linked-list", "Linked lists", "Implementing singly and doubly linked lists."),
            stubLesson("l-stack-queue", "Stacks and Queues", "Using list, deque, and when each shines."),
            stubLesson("l-trees", "Trees (basic)", "Binary trees, traversals (pre/in/post/level)."),
            stubLesson("l-graphs", "Graphs (basic)", "Adjacency list / matrix, BFS and DFS skeletons."),
            stubLesson("l-recursion-patterns", "Recursion patterns", "Divide-and-conquer, backtracking, memoization."),
            stubLesson("l-sorting", "Sorting", "Built-in Timsort, custom key, stability."),
            stubLesson("l-searching", "Searching", "Linear vs binary; bisect module."),
        ]
    )

    private static let typingAndModern = RoadmapBuilder.module(
        "mod-13-typing", "Typing and Modern Python",
        summary: "Type hints, generics, protocols, and how mypy fits in.",
        lessons: [
            stubLesson("l-type-hints", "Type hints basics", "-> int, x: str, list[int], dict[str, int]."),
            stubLesson("l-optional-union", "Optional, Union, and |", "X | None, PEP 604 unions, type narrowing."),
            stubLesson("l-generics", "Generics (TypeVar, Generic)", "Writing type-parametric utilities."),
            stubLesson("l-protocols", "Protocols (structural typing)", "typing.Protocol for duck-typed interfaces."),
            stubLesson("l-mypy", "mypy basics", "Running the type checker, strict mode, common errors."),
            stubLesson("l-type-aliases", "Type aliases and NewType", "type Foo = ..., NewType for nominal-lite typing."),
        ]
    )

    private static let standardLibraryDeepDive = RoadmapBuilder.module(
        "mod-14-stdlib", "Standard Library Deep Dive",
        summary: "The batteries every Python developer should know are included.",
        lessons: [
            stubLesson("l-collections-deep", "collections", "Counter, defaultdict, OrderedDict, deque, namedtuple."),
            stubLesson("l-itertools-deep", "itertools deep dive", "Beyond the basics: accumulate, batched, tee, starmap."),
            stubLesson("l-functools-deep", "functools deep dive", "cache, singledispatch, cached_property."),
            stubLesson("l-re", "re (regular expressions)", "Compiling patterns, groups, findall/finditer/sub."),
            stubLesson("l-json-vs-pickle", "json vs pickle", "When to interop (json) vs serialize Python-only (pickle)."),
            stubLesson("l-subprocess", "subprocess", "Running external commands safely."),
            stubLesson("l-argparse", "argparse for CLIs", "Building command-line interfaces the standard way."),
        ]
    )

    private static let practicalSkills = RoadmapBuilder.module(
        "mod-15-practical", "Practical Skills",
        summary: "HTTP, APIs, scraping, databases, environment — the toolkit for real projects.",
        lessons: [
            stubLesson("l-http", "HTTP requests (httpx / requests)", "GET/POST, headers, timeouts, sessions."),
            stubLesson("l-apis", "Working with REST APIs", "Auth, pagination, rate limits, error handling."),
            stubLesson("l-html-parsing", "Parsing HTML (BeautifulSoup)", "Selectors, extracting text, ethics of scraping."),
            stubLesson("l-sqlite", "Databases (sqlite3)", "Cursor, parameters, transactions."),
            stubLesson("l-env", "Environment variables and secrets", "os.environ, .env files, python-dotenv."),
            stubLesson("l-scraping-ethics", "Scraping ethics and robots.txt", "Play nice — rate limits, ToS, robots."),
        ]
    )

    private static let advancedTopics = RoadmapBuilder.module(
        "mod-16-advanced", "Advanced Topics",
        summary: "Metaclasses, descriptors, memory, and CPython internals for the curious.",
        lessons: [
            stubLesson("l-metaclasses", "Metaclasses", "type() as a class factory. When (rarely) to use one."),
            stubLesson("l-descriptors", "Descriptors", "__get__, __set__, __delete__ — how @property works underneath."),
            stubLesson("l-context-protocol", "Context manager protocol", "__enter__, __exit__, contextlib.contextmanager."),
            stubLesson("l-weakref", "Weak references", "weakref for caches without preventing GC."),
            stubLesson("l-gil", "The GIL and CPython internals", "What the Global Interpreter Lock does and doesn't prevent."),
            stubLesson("l-memory", "Memory management", "Reference counting, cycle collector, sys.getsizeof."),
            stubLesson("l-profiling", "Performance profiling", "cProfile, timeit, line_profiler."),
        ]
    )

    private static func stubLesson(_ id: String, _ title: String, _ summary: String) -> Lesson {
        RoadmapBuilder.lesson(id, title, summary: summary)
    }
}
