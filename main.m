#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
  CGDirectDisplayID mainDisplayID = CGMainDisplayID();
  // NSLog(@"Main display id=%d", mainDisplayID);

  while (true) {
    @autoreleasepool {
      CGPoint cursor = CGEventGetLocation(CGEventCreate(NULL));
      // NSLog(@"Mouse pos: (%f, %f)", cursor.x, cursor.y);
      CGRect rect = CGRectMake(cursor.x, cursor.y, 1, 1);
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
