"
An IllimaniProfilerMpHandlerTest is a test class for testing the behavior of IllimaniProfilerMpHandler
"
Class {
	#name : #IllimaniProfilerMpHandlerTest,
	#superclass : #TestCase,
	#instVars : [
		'handler'
	],
	#category : #'AllocationProfiler-Tests-Profiler'
}

{ #category : #running }
IllimaniProfilerMpHandlerTest >> setUp [

	super setUp.

	handler := IllimaniProfilerMpHandler new
]

{ #category : #tests }
IllimaniProfilerMpHandlerTest >> testShouldICaptureTheObject [

	handler classesToCapture: { Color . Point }.
	self assert: (handler shouldICaptureTheObject: Point new).
	self assert: (handler shouldICaptureTheObject: Color new)
]

{ #category : #tests }
IllimaniProfilerMpHandlerTest >> testShouldICaptureTheObjectCaptureAllObjects [

	handler captureAllObjects.
	handler classesToIgnore: { Point }.
	self deny: (handler shouldICaptureTheObject: Point new).
	self assert: (handler shouldICaptureTheObject: Point).
	self assert: (handler shouldICaptureTheObject: Color new).
	self assert: (handler shouldICaptureTheObject: nil)
]
