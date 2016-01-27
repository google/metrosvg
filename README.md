#MetroSVG

MetroSVG is a production-quality SVG renderer implementation for iOS
and OS X. It is used in Google Maps for iOS.

The library provides an Objective-C interface for iOS and a C
interface for iOS and OS X.

##Usage
    #import "MetroSVG/MetroSVG.h"
    
    NSData *svgData = ...;
    MSVGDocument *svgDocument = [[MSVGDocument alloc] initWithData:svgData];
    UIImage *svgImage = [svgDocument imageWithSize:svgDocument.size];

##Supported Features
MetroSVG is intended to cover the most common use cases of SVG in native iOS app development where designers create and export image assets using graphics tools such as Illustrator and Inkscape. Therefore, it is specialized for rendering of static images by design. Below is a list of SVG 1.1 features and their implementation status.


Feature | Status
--- | ---
Paths and Basic Shapes | Feature complete.
Coordinate Systems and Transformations | Feature complete.
Gradients | Near feature complete.
Fill and Stroke Properties | Near feature complete.
Document Structure | Only &lt;svg&gt; and &lt;g&gt; are implemented.
Styling (CSS) | An experimental implementation of class selector is available.
Clipping, Masking, Patterns, Markers, Length Units | Not implemented.
Text, Fonts, Filter Effects | Not implemented. Recommended to use other options.
Color Profile, Linking, Interactivity, Scripting, Animation | Out of scope.

##Discussion Forum
https://groups.google.com/forum/#!forum/metrosvg

##Disclaimer
MetroSVG is not an official Google product.
