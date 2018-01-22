This repo is no longer maintained, and doesn't work anymore. Sorry.

# persistent_enums [![Build Status](https://travis-ci.org/yglukhov/persistent_enums.svg?branch=master)](https://travis-ci.org/yglukhov/persistent_enums)
Define enums which values preserve their binary representation upon inserting or reordering

```nim
# Imagine you have the following enum
type MyEnum* = persistentEnum do:
    myFirstValue = 0
    mySecondValue

# You may store enum value in binary form to somewhere:
var serializedVal = mySecondValue
writeInt16ToSomewhere(cast[ptr int16](addr serializedVal))
```
```nim
# Then next version of your app may add more values to the enum, e.g.
type MyEnum* = persistentEnum do:
    myFirstValue = 0
    myNewlyInsertedValue
    mySecondValue

# Reading old binary value
var deserializedVal : MyEnum
readInt16FromSomewhere(cast[ptr int16](addr deserializedVal)

# With normal enums you would end up with deserializedVal == myNewlyInsertedValue
# But with persistent enum the following assertion will hold
assert(deserializedVal == mySecondValue)
```

## Under the hood
There is no runtime cost. Binary represenations of enum values are actually equal to crc16
of their string representation, unless the value is explicitly set in enum definition.
In case of collision a compile time error will be raised.
