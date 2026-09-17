#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>

static void drawText(CGContextRef ctx, NSString *value, CGFloat x, CGFloat y, CGFloat size, BOOL bold, CGColorRef color) {
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)(bold ? @"Helvetica-Bold" : @"Helvetica"), size, NULL);
    NSDictionary *attrs = @{(__bridge id)kCTFontAttributeName: (__bridge id)font,
                            (__bridge id)kCTForegroundColorAttributeName: (__bridge id)color};
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:value attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)str);
    CGContextSaveGState(ctx);
    CGContextSetTextPosition(ctx, x, y);
    CTLineDraw(line, ctx);
    CGContextRestoreGState(ctx);
    CFRelease(line);
    CFRelease(font);
}

static void overlayPage(PDFPage *page, CGContextRef ctx, BOOL english) {
    CGRect media = [page boundsForBox:kPDFDisplayBoxMediaBox];
    [page drawWithBox:kPDFDisplayBoxMediaBox toContext:ctx];

    // Rebuild the header inside the safe area with a visible top and left margin.
    CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(25, 744, 562, 48));
    drawText(ctx, @"VEPRIMI QYTETAR", 42, 770, 16, YES, [NSColor blackColor].CGColor);
    drawText(ctx, english ? @"CITIZEN-LED LEGISLATIVE INITIATIVE TO AMEND ALBANIA'S ELECTORAL CODE" : @"NISMË LIGJVËNËSE QYTETARE PËR NDRYSHIME NË KODIN ZGJEDHOR", 42, 754, 7.0, YES, [NSColor colorWithCalibratedRed:0.78 green:0.10 blue:0.16 alpha:1.0].CGColor);
    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithCalibratedRed:0.78 green:0.10 blue:0.16 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextMoveToPoint(ctx, 42, 746); CGContextAddLineToPoint(ctx, 570, 746); CGContextStrokePath(ctx);

    // Replace the small deadline panel with a stronger, bordered notice.
    // Remove the old white panel completely, then draw a single aligned panel.
    CGContextSetFillColorWithColor(ctx, [NSColor colorWithCalibratedRed:0.97 green:0.91 blue:0.93 alpha:1.0].CGColor);
    CGContextFillRect(ctx, CGRectMake(192, 681, 180, 54));
    CGRect panel = CGRectMake(198, 684, 168, 46);
    NSColor *red = [NSColor colorWithCalibratedRed:0.78 green:0.10 blue:0.16 alpha:1.0];
    NSColor *green = [NSColor colorWithCalibratedRed:0.08 green:0.25 blue:0.22 alpha:1.0];
    CGContextSetFillColorWithColor(ctx, [NSColor colorWithCalibratedRed:1.0 green:0.95 blue:0.78 alpha:1.0].CGColor);
    CGContextFillRect(ctx, panel);
    CGContextSetStrokeColorWithColor(ctx, green.CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextStrokeRect(ctx, CGRectInset(panel, 0.5, 0.5));

    if (english) {
        drawText(ctx, @"SIGNATURE DEADLINE:", 203, 714, 7.6, YES, green.CGColor);
        drawText(ctx, @"15 DECEMBER 2026", 203, 699, 10.0, YES, red.CGColor);
    } else {
        drawText(ctx, @"AFATI I FIRMAVE:", 203, 714, 7.6, YES, green.CGColor);
        drawText(ctx, @"15 DHJETOR 2026", 203, 699, 10.0, YES, red.CGColor);
    }

    // Add a second, clearly labelled QR code for the Facebook page beside the
    // existing website QR code in the lower-right whitespace.
    NSURL *qrURL = [NSURL fileURLWithPath:@"facebook-qr.png"];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)qrURL, NULL);
    CGImageRef facebookQR = source ? CGImageSourceCreateImageAtIndex(source, 0, NULL) : NULL;
    if (source) CFRelease(source);
    if (facebookQR) {
        CGRect qrBox = CGRectMake(404, 78, 65, 82);
        CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
        CGContextFillRect(ctx, qrBox);
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
        CGContextDrawImage(ctx, CGRectMake(409, 87, 55, 55), facebookQR);
        drawText(ctx, @"FACEBOOK", 436, 82, 5.0, YES, red.CGColor);
        CGImageRelease(facebookQR);
    }

    // Rebuild the lower callout so the QR area cannot cut off the black block.
    CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(35, 154, 540, 68));
    CGContextSetFillColorWithColor(ctx, [NSColor colorWithCalibratedWhite:0.08 alpha:1.0].CGColor);
    CGContextAddPath(ctx, CGPathCreateWithRoundedRect(CGRectMake(42, 167, 410, 43), 7, 7, NULL));
    CGContextFillPath(ctx);
    NSString *callout = english ? @"GET INFORMED. READ THE DRAFT. DECIDE WHETHER YOU WANT TO SUPPORT IT." : @"INFORMOHU. LEXO DRAFTIN. VENDOS NËSE DËSHIRON TA MBËSHTESËSH.";
    drawText(ctx, callout, 52, 184, 8.0, YES, [NSColor whiteColor].CGColor);
}

static BOOL updatePDF(NSString *input, NSString *output, BOOL english, BOOL bilingual) {
    PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:input]];
    if (!doc) return NO;
    CGRect media = [[doc pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox];
    NSURL *url = [NSURL fileURLWithPath:output];
    CGContextRef ctx = CGPDFContextCreateWithURL((__bridge CFURLRef)url, &media, NULL);
    if (!ctx) return NO;
    for (NSInteger i = 0; i < doc.pageCount; i++) {
        PDFPage *page = [doc pageAtIndex:i];
        CGRect pageMedia = [page boundsForBox:kPDFDisplayBoxMediaBox];
        // Render at 4x (approximately 288 DPI) before writing the page. This
        // deliberately flattens the old text layer so the superseded deadline
        // cannot remain searchable underneath the corrected notice.
        size_t scale = 4;
        size_t width = (size_t)ceil(CGRectGetWidth(pageMedia) * scale);
        size_t height = (size_t)ceil(CGRectGetHeight(pageMedia) * scale);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGImageAlphaNoneSkipLast);
        CGColorSpaceRelease(colorSpace);
        if (!bitmap) { CGPDFContextClose(ctx); return NO; }
        CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
        CGContextScaleCTM(bitmap, scale, scale);
        overlayPage(page, bitmap, bilingual ? (i == 1) : english);
        CGImageRef image = CGBitmapContextCreateImage(bitmap);
        CGPDFContextBeginPage(ctx, (__bridge CFDictionaryRef)@{(__bridge id)kCGPDFContextMediaBox: [NSValue valueWithRect:pageMedia]});
        CGContextDrawImage(ctx, pageMedia, image);
        CGPDFContextEndPage(ctx);
        CGImageRelease(image);
        CGContextRelease(bitmap);
    }
    CGPDFContextClose(ctx);
    return YES;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 4) {
            fprintf(stderr, "usage: update_leaflet_deadline input.pdf output.pdf language(al|en|bilingual)\n");
            return 2;
        }
        NSString *lang = [NSString stringWithUTF8String:argv[3]];
        BOOL bilingual = [lang isEqualToString:@"bilingual"];
        BOOL english = [lang isEqualToString:@"en"];
        return updatePDF([NSString stringWithUTF8String:argv[1]], [NSString stringWithUTF8String:argv[2]], english, bilingual) ? 0 : 1;
    }
}
