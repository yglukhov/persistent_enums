##
## Persistent enums. Use symbolic names for constants with auto-generated
## int values. The enum can later be expanded by inserting new items to any
## position still preserving numeric values for old items. This is useful in
## case when you want to preserve binary (or protocol) backwards compatibility.
##
import macros, tables, sequtils, algorithm

proc crc16(data: string): uint16 =
  var x: uint8
  var crc = 0xFFFF'u16

  for i in 0 ..< data.len:
    x = uint8((crc shr 8) xor uint16(ord(data[i])))
    x = x xor (x shr 4)
    crc = (crc shl 8) xor (x shl 12) xor (x shl 5) xor x
  return crc

macro persistent*(b: untyped{nkTypeDef}): untyped =
  result = b
  let enumTy = b[2]
  enumTy.expectKind(nnkEnumTy)

  var allFields = initTable[int32, NimNode]()
  for ef in enumTy:
    if ef.kind != nnkEmpty:
      var elemName: string
      var elemValue: int32
      var elem = ef

      if ef.kind == nnkEnumFieldDef:
        elem = ef[0]
        elemName = $elem
        elemValue = int32(ef[1].intVal)
      else:
        elemName = $elem
        elemValue = int32(crc16(elemName))

      doAssert(elemValue notin allFields, "Error: hash of enum value " & elemName & " collides with " & $allFields[elemValue])
      allFields[elemValue] = elem

  var allKeys = toSeq(allFields.keys())
  allKeys.sort()

  let newEnumTy = newTree(nnkEnumTy, newEmptyNode())

  for k in allKeys:
    newEnumTy.add(newNimNode(nnkEnumFieldDef).add(allFields[k], newLit(k)))

  result[2] = newEnumTy

when isMainModule:
  type MyEnum {.persistent.} = enum
    myValue0 = 0
    myValue1
    myValue2
    myValue3

  static:
    doAssert(myValue0.int == 0, "Persistent enum sanity check failed")
    doAssert(myValue1.int == 10916, "Persistent enum sanity check failed")
    doAssert(myValue2.int == 10951, "Persistent enum sanity check failed")
    doAssert(myValue3.int == 10982, "Persistent enum sanity check failed")

    var t = myValue3
    doAssert(t == myValue3, "Persistent enum sanity check failed")
