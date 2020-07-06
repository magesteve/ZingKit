# ZingKit - A Swift based Animation Sequencer for UIView style animation.

## Description

Using chained dot notation, a developer can create a sequence of animation commands (internally called a cell).  Once created, the sequence can be executed (start the animation running), and once running, the sequence can be safely canceled.

Most cells are executed in a sequential manner, where each cell is started and finished before the next cell is started. Thus a list of cells (the Zing object) starts when the first cell starts, and ends when the last cell finishes. Most cells have associated closures.

UIView style animation involves changing animatable properties of a UIVIew within an UIView.animate() call.  Apple's documentation describes this in more detail.  An animation cell defined by the thenAnimate() call invokes the associated closure within a UIView.animate() call.

Other cells can be timed delays (nothing happening until the delay is over), non-animated immediate actions
(ie. not within UIView.animate call) or immediate animated actions (called within UIView.animate). Both of the last two immediate actions do not wait for the animation to complete but immediately calls the next cell in the sequence.

Zing is well suited for simple sequence of UIView animation. It is not designed for interactive animations, thought it can animate background views within game. 

## Documentation

All public classes, protocols, properties & functions have inline documentation (DOxygen style).  Further explanation of the Framework, refer to the ZingDemo repository.

## Requirements

ZingKit is targeted for the last versions of iOS and the Swift programming languages.

## Installation

ZingKit is a Swift Package. Add Package Dependency using the https://github.com/magesteve/ZingKit address.

## Example

To create a Zing animation, use the static class call Start(tite:).  Add animation cells to the sequence using the thenAnimate(duration:action:) method.  Start the animation, but using the execute() method. Since the calls usually returns a reference to the Zing object being referenced, Swift Dot Notation can be used to chain a series of commands into an easy to read statement.

Eample #1

Zing.Start()
  .thenAnimate(1.0) {
    v.position = firstPos
  }
  .thenAnimate(1.0) {
    v.position = secondPos
  }
  .thenAnimate(1.0) {
    v.position = initialPos
  }
  .execute()

Example #1 is a fully formed Zing animation. It would move the view from it's initilPos, to the first position, then to the second position, then back the initial position. Each movement would take a second.

Review the Project ZingLab to see a more detailed example.

### Steve Sheets, magesteve@mac.com

Originally from Silicon Valley, Steve has been embedded in the software industry for over 35 years. As an expert in user interface and design, he started developer desktop applications for companies like Apple and AOL, moved into mobile development, and is now working in the virtual reality and Augment Reality space.  He has taught Objective-C & Swift development classes (MoDev, Learning Tree), as well as given talk on variety of developer topics (DC Mac Dev group, Capital One Swift Conference).  He is an avid game player, swordsman and an occasional game designer

## License

ZingKit is available under the MIT license.
