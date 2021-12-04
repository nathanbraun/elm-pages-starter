---
title: elm-pages v2 starter with tailwind and A/B tests 
description: starting point for all my projects
type: page
published: "2021-12-01"
---

# elm-pages v2 + tailwind + a/b test starter page
This is my elm-pages v2, tailwind, SPLAT route, A/B testing starter page

## elm-pages 2.0
Now no webpack required.

## Tailwind
With matteus23/elm-tailwind-modules

## Model available in Renderer
Needed this for keeping track of AB tests (see below)

## Renderer can send Shared Messages
Not only can renderer keep track of model, it can also send Shared messages.
The button below outputs some text to the console via a Shared Msg and Debug.

<button label="Click Me!"/>

## SLAT routes
Set up so that it matches anything (including nested pages) in content folder

- [foo](foo) (in ./content/foo.md)
- [bar](bar) (in ./content/bar/index.md)
- [bar/baz](bar/baz) (in ./content/bar/baz.md)

## AB Tests
Includes a some code that makes it easier to run AB tests.

Just add the name of a test:

```elm
tests : List TestId
tests =
    [ TestId "example-test"
    ]
```

Then wrap version A and B in your markdown files:

```elm
<test id="example-test" version="A">
### Version A
This is an AB test! You are viewing version A.
</test>
<test id="example-test" version="B">
### Version B
This is an AB test! You are viewing version B.
</test>
```

Here's the result:

<test id="example-test" version="A">
### Version A
This is an AB test! You are viewing version A.
</test>
<test id="example-test" version="B">
### Version B
This is an AB test! You are viewing version B.
</test>

Tests are saved in local storage so they persist across users/devices. The
workflow is: (1) look for the test in local storage, if it's there, load the
version the user has seen, if not, (2) randomly pick a version to show, (3)
write that to local storage so the user sees it next time, (4) clear out any
old tests.
