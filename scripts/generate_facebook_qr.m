#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) return 2;
        NSString *output = [NSString stringWithUTF8String:argv[1]];
        NSString *url = @"https://www.facebook.com/people/Veprimi-Qytetar/61587608996389/";
        CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        if (!filter) { NSLog(@"No QR filter"); return 1; }
        [filter setValue:[url dataUsingEncoding:NSUTF8StringEncoding] forKey:@"inputMessage"];
        [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
        CIImage *code = filter.outputImage;
        if (!code) { NSLog(@"No QR output"); return 1; }
        CGFloat scale = 20.0;
        CGRect extent = code.extent;
        NSLog(@"extent %@", NSStringFromRect(extent));
        CIImage *scaled = [code imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
        NSLog(@"scaled %@", NSStringFromRect(scaled.extent));
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef image = [context createCGImage:scaled fromRect:scaled.extent];
        if (!image) { NSLog(@"Could not render QR image"); return 1; }
        NSURL *fileURL = [NSURL fileURLWithPath:output];
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, (__bridge CFStringRef)UTTypePNG.identifier, 1, NULL);
        CGImageDestinationAddImage(destination, image, NULL);
        BOOL ok = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        CGImageRelease(image);
        return ok ? 0 : 1;
    }
}
