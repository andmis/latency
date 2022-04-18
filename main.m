#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
  CGDirectDisplayID mainDisplayID = CGMainDisplayID();
  CGSize mainDisplaySize = CGDisplayBounds(mainDisplayID).size;
  NSLog(@"Main display id=%d, (width, height)=(%f, %f)", mainDisplayID, mainDisplaySize.width, mainDisplaySize.height);

  while (true) {
    @autoreleasepool {
      // Grab the current mouse location.
      NSPoint mouseLoc = [NSEvent mouseLocation];
      CGPoint cgPoint = NSPointToCGPoint(mouseLoc);
      // The coordinate systems are funky.
      cgPoint.y = mainDisplaySize.height - cgPoint.y;
      // NSLog(@"Mouse pos: (%f, %f)", cgPoint.x, cgPoint.y);

      // Grab the color at the pixel under the cursor.
      CGRect rect = CGRectMake(cgPoint.x, cgPoint.y, 1, 1);
      CGImageRef image = CGDisplayCreateImageForRect(mainDisplayID, rect);
      NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
      CGImageRelease(image);
      NSColor *color = [bitmap colorAtX:0 y:0];
      NSLog(@"%@", color);
      [bitmap release];
    }
  }
  return 0;
}
