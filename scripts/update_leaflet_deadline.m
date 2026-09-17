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
    // Stop just before the explanatory copy on the right so the cleanup
    // background does not obscure its first line.
    CGContextFillRect(ctx, CGRectMake(190, 674, 380, 68));
    CGRect panel = CGRectMake(198, 680, 168, 54);
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

    // Restore the explanatory paragraph beside the deadline after cleaning
    // the old panel background, keeping every word fully visible.
    NSColor *body = [NSColor colorWithCalibratedWhite:0.08 alpha:1.0];
    if (english) {
        drawText(ctx, @"Signature does not automatically enact", 370, 718, 7.0, NO, body.CGColor);
        drawText(ctx, @"the bill. It gives the initiative the legal", 370, 706, 7.0, NO, body.CGColor);
        drawText(ctx, @"basis to be submitted to Parliament.", 370, 694, 7.0, NO, body.CGColor);
    } else {
        drawText(ctx, @"Firma nuk e miraton automatikisht ligjin.", 370, 718, 7.0, NO, body.CGColor);
        drawText(ctx, @"Ajo i jep nismës bazën ligjore për t'u", 370, 706, 7.0, NO, body.CGColor);
        drawText(ctx, @"paraqitur në Kuvend.", 370, 694, 7.0, NO, body.CGColor);
    }

    // Add a second, clearly labelled QR code for the Facebook page beside the
    // existing website QR code in the lower-right whitespace.
    NSURL *qrURL = [NSURL fileURLWithPath:@"facebook-qr.png"];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)qrURL, NULL);
    CGImageRef facebookQR = source ? CGImageSourceCreateImageAtIndex(source, 0, NULL) : NULL;
    if (source) CFRelease(source);
    if (facebookQR) {
        // Remove the previous Facebook QR placement from the source leaflet.
        CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
        CGContextFillRect(ctx, CGRectMake(395, 70, 78, 95));
        CGRect qrBox = CGRectMake(42, 78, 85, 82);
        CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
        CGContextFillRect(ctx, qrBox);
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
        CGContextDrawImage(ctx, CGRectMake(47, 87, 55, 55), facebookQR);
        // Keep both lines centered beneath this QR and inside its own box.
        drawText(ctx, english ? @"FACEBOOK PAGE" : @"FAQJA FACEBOOK", 47, 82, 4.0, YES, red.CGColor);
        drawText(ctx, @"VEPRIMI QYTETAR", 47, 76, 4.0, YES, red.CGColor);
        CGImageRelease(facebookQR);
    }

    // Replace the generic label under the existing reform website QR code.
    CGContextSetFillColorWithColor(ctx, [NSColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(472, 70, 104, 18));
    drawText(ctx, english ? @"ELECTORAL CODE REFORM WEBSITE" : @"FAQJA PËR REFORMËN ZGJEDHORE", 474, 76, 4.0, YES, [NSColor colorWithCalibratedWhite:0.08 alpha:1.0].CGColor);

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
