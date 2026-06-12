import ObjectiveC.runtime
import XCTest

@objcMembers
private final class FakePictureInPictureController: NSObject {
  dynamic var requiresLinearPlayback = false
  private(set) var appliedControlStyles: [NSNumber] = []

  override func setValue(_ value: Any?, forKey key: String) {
    if key == "controlsStyle" {
      if let number = value as? NSNumber {
        appliedControlStyles.append(number)
      }
      return
    }

    super.setValue(value, forKey: key)
  }
}

private final class DeinitAwareView: UIView {
  var onDeinit: (() -> Void)?

  deinit {
    onDeinit?()
  }
}

final class RunnerTests: XCTestCase {
  func testPipOptionsViewPropertiesUseWeakReferences() {
    guard let pipOptionsClass = NSClassFromString("PipOptions") else {
      return XCTFail("PipOptions class not found at runtime")
    }

    assertPropertyAttributes(
      of: pipOptionsClass,
      named: "sourceContentView",
      contains: "W"
    )
    assertPropertyAttributes(
      of: pipOptionsClass,
      named: "contentView",
      contains: "W"
    )
  }

  func testPipControllerInternalViewPropertiesUseWeakReferences() {
    guard let pipControllerClass = NSClassFromString("PipController") else {
      return XCTFail("PipController class not found at runtime")
    }

    assertPropertyAttributes(
      of: pipControllerClass,
      named: "contentView",
      contains: "W"
    )
    assertPropertyAttributes(
      of: pipControllerClass,
      named: "contentViewOriginalParentView",
      contains: "W"
    )
  }

  func testPipControllerKeepsPrivateControlStyleEntryPoint() {
    guard let pipControllerClass = NSClassFromString("PipController") else {
      return XCTFail("PipController class not found at runtime")
    }

    XCTAssertNotNil(
      class_getInstanceMethod(
        pipControllerClass,
        NSSelectorFromString("applyControlStyle:")
      ),
      "Expected PipController to keep the private control-style entry point"
    )
    assertPropertyAttributes(
      of: pipControllerClass,
      named: "privateControlsStyleApplied",
      contains: "TB"
    )
  }

  func testPipControllerAppliesAndResetsPrivateControlStyles() {
    guard let pipControllerClass = NSClassFromString("PipController") as? NSObject.Type else {
      return XCTFail("PipController class not found at runtime")
    }

    let controller = pipControllerClass.init()
    let fakePictureInPictureController = FakePictureInPictureController()
    controller.setValue(fakePictureInPictureController, forKey: "pipController")

    let applySelector = NSSelectorFromString("applyControlStyle:")
    XCTAssertTrue(controller.responds(to: applySelector))
    guard let method = class_getInstanceMethod(pipControllerClass, applySelector) else {
      return XCTFail("applyControlStyle: method not found")
    }
    typealias ApplyControlStyleFn = @convention(c) (AnyObject, Selector, Int32) -> Void
    let implementation = method_getImplementation(method)
    let applyControlStyle = unsafeBitCast(
      implementation,
      to: ApplyControlStyleFn.self
    )

    applyControlStyle(controller, applySelector, 2)
    XCTAssertTrue(fakePictureInPictureController.requiresLinearPlayback)
    XCTAssertEqual(fakePictureInPictureController.appliedControlStyles.last, 1)

    applyControlStyle(controller, applySelector, 0)
    XCTAssertFalse(fakePictureInPictureController.requiresLinearPlayback)
    XCTAssertEqual(fakePictureInPictureController.appliedControlStyles.last, 0)
  }

  func testPipControllerRestoresContentViewAfterMovingBetweenParents() {
    guard let pipControllerClass = NSClassFromString("PipController") as? NSObject.Type else {
      return XCTFail("PipController class not found at runtime")
    }

    let controller = pipControllerClass.init()
    let originalParent = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
    let newParent = UIView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))

    var deinitCalled = false
    weak var weakManagedContentView: DeinitAwareView?

    func installManagedContentView() {
      let managedContentView = DeinitAwareView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
      managedContentView.translatesAutoresizingMaskIntoConstraints = false
      managedContentView.onDeinit = {
        deinitCalled = true
      }

      weakManagedContentView = managedContentView
      originalParent.addSubview(managedContentView)
      controller.setValue(managedContentView, forKey: "contentView")
    }

    installManagedContentView()
    guard weakManagedContentView != nil else {
      return XCTFail("Failed to create content view")
    }

    invokeVoidSelector(
      named: "insertContentViewIfNeeded:",
      on: controller,
      object: newParent,
      owner: pipControllerClass
    )

    guard let insertedContentView = weakManagedContentView else {
      return XCTFail("contentView should stay alive after being inserted into the new parent")
    }
    XCTAssertTrue(newParent.subviews.contains(insertedContentView))
    XCTAssertFalse(originalParent.subviews.contains(insertedContentView))
    XCTAssertFalse(deinitCalled, "contentView should stay alive while it is managed by a parent view")

    invokeVoidSelector(
      named: "restoreContentViewIfNeeded",
      on: controller,
      owner: pipControllerClass
    )

    guard let restoredContentView = weakManagedContentView else {
      return XCTFail("contentView should still be alive after restoration")
    }

    XCTAssertTrue(originalParent.subviews.contains(restoredContentView))
    XCTAssertFalse(newParent.subviews.contains(restoredContentView))
    XCTAssertEqual(restoredContentView.frame, CGRect(x: 10, y: 20, width: 30, height: 40))
    XCTAssertFalse(deinitCalled, "contentView should remain alive after restoration")
  }

  private func assertPropertyAttributes(
    of cls: AnyClass,
    named propertyName: String,
    contains expectedFragment: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard let property = class_getProperty(cls, propertyName) else {
      return XCTFail(
        "Expected property \(propertyName) on \(NSStringFromClass(cls))",
        file: file,
        line: line
      )
    }

    guard let rawAttributes = property_getAttributes(property) else {
      return XCTFail(
        "Expected attributes for \(propertyName) on \(NSStringFromClass(cls))",
        file: file,
        line: line
      )
    }

    let attributes = String(cString: rawAttributes)
    XCTAssertTrue(
      attributes.contains(expectedFragment),
      "Expected \(propertyName) attributes to contain \(expectedFragment), got \(attributes)",
      file: file,
      line: line
    )
  }

  private func invokeVoidSelector(
    named selectorName: String,
    on object: AnyObject,
    owner cls: AnyClass
  ) {
    let selector = NSSelectorFromString(selectorName)
    guard let method = class_getInstanceMethod(cls, selector) else {
      return XCTFail("Expected selector \(selectorName) on \(NSStringFromClass(cls))")
    }

    typealias VoidMethod = @convention(c) (AnyObject, Selector) -> Void
    let implementation = method_getImplementation(method)
    let function = unsafeBitCast(implementation, to: VoidMethod.self)
    function(object, selector)
  }

  private func invokeVoidSelector(
    named selectorName: String,
    on object: AnyObject,
    object argument: AnyObject,
    owner cls: AnyClass
  ) {
    let selector = NSSelectorFromString(selectorName)
    guard let method = class_getInstanceMethod(cls, selector) else {
      return XCTFail("Expected selector \(selectorName) on \(NSStringFromClass(cls))")
    }

    typealias ObjectMethod = @convention(c) (AnyObject, Selector, AnyObject) -> Void
    let implementation = method_getImplementation(method)
    let function = unsafeBitCast(implementation, to: ObjectMethod.self)
    function(object, selector, argument)
  }
}
