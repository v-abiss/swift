// RUN: %target-swiftc_driver -O -Rpass-missed=sil-opt-remark-gen -Xllvm -sil-disable-pass=FunctionSignatureOpts -emit-sil %s -o /dev/null -Xfrontend -verify

// RUN: %empty-directory(%t)
// RUN: %target-swiftc_driver -wmo -O -Xllvm -sil-disable-pass=FunctionSignatureOpts -emit-sil -save-optimization-record=yaml  -save-optimization-record-path %t/note.yaml %s -o /dev/null && %FileCheck --input-file=%t/note.yaml %s

// REQUIRES: optimized_stdlib,swift_stdlib_no_asserts

// This file is testing out the basic YAML functionality to make sure that it
// works without burdening opt-remark-generator-yaml.swift with having to update all
// of the yaml test cases everytime new code is added.

public class Klass {}

// CHECK: --- !Missed
// CHECK-NEXT: Pass:            sil-opt-remark-gen
// CHECK-NEXT: Name:            sil.memory
// CHECK-NEXT: DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift',
// CHECK-NEXT:                    Line: [[# @LINE + 7 ]], Column: 21 }
// CHECK-NEXT: Function:        main
// CHECK-NEXT: Args:
// CHECK-NEXT:   - String:          'heap allocated ref of type '''
// CHECK-NEXT:   - ValueType:       Klass
// CHECK-NEXT:   - String:          ''''
// CHECK-NEXT: ...
public var global = Klass() // expected-remark {{heap allocated ref of type 'Klass'}}

// CHECK: --- !Missed
// CHECK-NEXT: Pass:            sil-opt-remark-gen
// CHECK-NEXT: Name:            sil.memory
// CHECK-NEXT: DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift', 
// CHECK-NEXT:                    Line: [[# @LINE + 27 ]], Column: 12 }
// CHECK-NEXT: Function:        'getGlobal()'
// CHECK-NEXT: Args:
// CHECK-NEXT:   - String:          'begin exclusive access to value of type '''
// CHECK-NEXT:   - ValueType:       Klass
// CHECK-NEXT:   - String:          ''''
// CHECK-NEXT:   - InferredValue:   'of ''global'''
// CHECK-NEXT:     DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift', 
// CHECK-NEXT:                        Line: [[# @LINE - 14 ]], Column: 12 }
// CHECK-NEXT: ...
//
// CHECK: --- !Missed
// CHECK-NEXT: Pass:            sil-opt-remark-gen
// CHECK-NEXT: Name:            sil.memory
// CHECK-NEXT: DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift',
// CHECK-NEXT:                    Line: [[# @LINE + 12]], Column: 5 }
// CHECK-NEXT: Function:        'getGlobal()'
// CHECK-NEXT: Args:
// CHECK-NEXT:   - String:          'retain of type '''
// CHECK-NEXT:   - ValueType:       Klass
// CHECK-NEXT:   - String:          ''''
// CHECK-NEXT:   - InferredValue:   'of ''global'''
// CHECK-NEXT:     DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift',
// CHECK-NEXT:                        Line: [[# @LINE - 29 ]], Column: 12 }
// CHECK-NEXT: ...
@inline(never)
public func getGlobal() -> Klass {
    return global // expected-remark @:5 {{retain of type 'Klass'}}
                  // expected-note @-34:12 {{of 'global'}}
                  // expected-remark @-2 {{begin exclusive access to value of type 'Klass'}}
                  // expected-note @-36:12 {{of 'global'}}
}

// CHECK: --- !Missed
// CHECK-NEXT: Pass:            sil-opt-remark-gen
// CHECK-NEXT: Name:            sil.memory
// CHECK-NEXT: DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift',
// CHECK-NEXT:                    Line: [[# @LINE + 23]], Column: 11 }
// CHECK-NEXT: Function:        'useGlobal()'
// CHECK-NEXT: Args:
// CHECK-NEXT:   - String:          'heap allocated ref of type '''
// CHECK-NEXT:   - ValueType:
// CHECK-NEXT:   - String:          ''''
// CHECK-NEXT: ...
// CHECK-NEXT: --- !Missed
// CHECK-NEXT: Pass:            sil-opt-remark-gen
// CHECK-NEXT: Name:            sil.memory
// CHECK-NEXT: DebugLoc:        { File: '{{.*}}opt-remark-generator-yaml.swift',
// CHECK-NEXT:                    Line: [[# @LINE + 12]], Column: 12 }
// CHECK-NEXT: Function:        'useGlobal()'
// CHECK-NEXT: Args:
// CHECK-NEXT:   - String:          'release of type '''
// CHECK-NEXT:   - ValueType:
// CHECK-NEXT:   - String:          ''''
// CHECK-NEXT: ...

public func useGlobal() {
    let x = getGlobal()
    // Make sure that the retain msg is at the beginning of the print and the
    // releases are the end of the print.
    print(x) // expected-remark @:11 {{heap allocated ref of type}}
             // We test the type emission above since FileCheck can handle regex.
             // expected-remark @-2:12 {{release of type}}
}
