# README

This is my elm-pages v2, tailwind, SPLAT route, A/B testing starter page

## elm-pages 2.0
Now no webpack required.

## Model available in Renderer
Needed this for keeping track of AB tests (see below)

## Renderer can send Shared Messages
Renderer can also also send Shared messages.

## Tailwind
With matteus23/elm-tailwind-modules

## SPLAT routes
Set up so that it matches anything (including nested pages) in content folder

## Google Analytics
Set up to track page views in Google Analytics. Just need to add your id.

## AB Tests
Includes a some code that makes it easier to run AB tests.


Just add the name of a test (in Shared.elm)

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

Tests are saved in local storage so they persist across users/devices. The
workflow is: (1) look for the test in local storage, if it's there, load the
version the user has seen, if not, (2) randomly pick a version to show, (3)
write that to local storage so the user sees it next time, (4) clear out any
old tests.
