# rysh

Fun with execvp!

Why use a well-written shell when you can roll your own?

## Compiling

    $ make

## Usage
    $ ./rysh
    rysh> ls

## Testing
    $ make testall
Runs all tests, outputs score

    $ make n=<num> test
Runs the specific test number `num`

## Notes

This compiles fine on most UNIX machines; OSX 10.6 was missing strndup so I threw my own in there for now.
