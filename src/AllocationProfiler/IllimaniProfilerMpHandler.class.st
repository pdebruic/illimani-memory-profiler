"
I am a class that defines the logic to only registed an specific type of object. I am a subclass of MpHandler, which is required by the method proxy framework. I use the method proxy framework to capture the object allocations.

Please define my `classesToRegister` variable with the classes you want to capture or if you want to capture all use the message `captureAllObjects`
"
Class {
	#name : #IllimaniProfilerMpHandler,
	#superclass : #MpHandler,
	#instVars : [
		'objectAllocations',
		'classesToAvoidInTheContextSearch',
		'captureAllObjects',
		'copyExecutionStack',
		'classesToCapture',
		'classesToIgnore',
		'graphWalker',
		'keepTheAllocatedObjects'
	],
	#category : #'AllocationProfiler-Profiler'
}

{ #category : #evaluating }
IllimaniProfilerMpHandler >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [

	(self shouldICaptureTheObject: returnValue) ifTrue: [
		self handleAllocationOfObject: returnValue ].
	^ returnValue
]

{ #category : #api }
IllimaniProfilerMpHandler >> captureAllObjects [
	"When this turned to true I will capture all the allocations of all the objects"

	captureAllObjects := true.
	"It is necessary to put an empty array when wanting to capture all object allocations"
	self classesToCapture: {  }
]

{ #category : #accessing }
IllimaniProfilerMpHandler >> classesToCapture [

	^ classesToCapture
]

{ #category : #accessing }
IllimaniProfilerMpHandler >> classesToCapture: aCollection [

	classesToCapture := aCollection
]

{ #category : #accessing }
IllimaniProfilerMpHandler >> classesToIgnore: aCollection [

	classesToIgnore := aCollection
]

{ #category : #api }
IllimaniProfilerMpHandler >> cleanAllocations [

	objectAllocations removeAll
]

{ #category : #evaluating }
IllimaniProfilerMpHandler >> contextThatAllocatedTheObject: aContext forClass: aClass [

	| sender |
	sender := aContext sender.
	[
	sender receiver class = aClass or: [
		sender receiver class = aClass class or: [
			classesToAvoidInTheContextSearch includes: sender receiver class ] ] ]
		whileTrue: [ sender := sender sender ].
	^ sender
]

{ #category : #api }
IllimaniProfilerMpHandler >> copyExecutionStack [
	"When this is set to true, for each object allocationn the full execution stack from which
	the method was created will be copied and store. This information will be available for
	making analysis. Keep in mind that when there is a lot of allocations going the size of
	the image can grow quickly and drastically."

	copyExecutionStack := true
]

{ #category : #initialization }
IllimaniProfilerMpHandler >> defaultClassesToAvoidInTheContextSearch [

	^{
		IllimaniProfilerMpHandler.
		MpMethodProxy.
		BlockClosure.
		FullBlockClosure.
		CompiledBlock }
]

{ #category : #api }
IllimaniProfilerMpHandler >> doNotCaptureAllObjects [
	"See the comment of my opposite method"

	captureAllObjects := false
]

{ #category : #api }
IllimaniProfilerMpHandler >> doNotCopyExecutionStack [
	"See the comment of my opposite method"

	copyExecutionStack := false
]

{ #category : #evaluating }
IllimaniProfilerMpHandler >> handleAllocationOfObject: newlyAllocatedObject [

	| filteredContext timeNow allocationInformationHolder totalSizeInBytes |
	timeNow := DateAndTime now.
	allocationInformationHolder := AllocationInfoDTO new.
	filteredContext := self contextThatAllocatedTheObject: thisContext forClass: newlyAllocatedObject class.
	copyExecutionStack ifTrue: [ allocationInformationHolder context: filteredContext copyStack ].
	keepTheAllocatedObjects ifTrue: [ allocationInformationHolder allocatedObject: newlyAllocatedObject "allocatedObjectHash: newlyAllocatedObject hash"].
	totalSizeInBytes := (graphWalker rootObject: newlyAllocatedObject) totalSizeInBytes.

	allocationInformationHolder
		allocatorClass: filteredContext receiver class;
		allocatorMethodName: (filteredContext receiver class name asString , '>>#' , filteredContext compiledCode method selector asString);
		allocatedObjectClass: newlyAllocatedObject class;
		totalSizeInBytes: totalSizeInBytes;
		timestamp: timeNow.

	objectAllocations add: allocationInformationHolder
]

{ #category : #initialization }
IllimaniProfilerMpHandler >> initialize [

	super initialize.
	self doNotCopyExecutionStack.
	self doNotCaptureAllObjects.
	keepTheAllocatedObjects := false.
	classesToCapture := {  }.
	classesToIgnore := {  }.
	objectAllocations := OrderedCollection new.
	graphWalker := GraphSpaceStatistics new.
	self initializeClassesToAvoidInContextSearch
]

{ #category : #initialization }
IllimaniProfilerMpHandler >> initializeClassesToAvoidInContextSearch [

	classesToAvoidInTheContextSearch := self defaultClassesToAvoidInTheContextSearch ,
		(self defaultClassesToAvoidInTheContextSearch collect: [ :aClass | aClass class ])
]

{ #category : #api }
IllimaniProfilerMpHandler >> keepTheAllocatedObjects [
	"When this turned to true I will copy all the allocated of all the objects"

	"Keep in mind that with option turned on it will affect the GC.
	All the allocated objects will be referenced, because we are keeping them.
	So the GC because it will never discard any of the objects."

	keepTheAllocatedObjects := true
]

{ #category : #accessing }
IllimaniProfilerMpHandler >> objectAllocations [

	^ objectAllocations
]

{ #category : #testing }
IllimaniProfilerMpHandler >> shouldICaptureTheObject: returnValue [

	^ (captureAllObjects or: [ classesToCapture includes: returnValue class ]) and: [
		  (classesToIgnore includes: returnValue class) not ]
]
