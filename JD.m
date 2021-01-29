//
//  JD.m
//  cdawldicom
//
//  Created by pcs on 29/1/21.
//  Copyright © 2021 opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>

static uint8 spacepadding=' ';
static uint8 zeropadding=0;
static uint16 lengthzero=0;
static uint16 lengthfour=4;
static uint16 lengtheight=8;

#pragma mark TODO encodings...

void JD(NSDictionary *J, NSMutableData *D)
{
    NSMutableDictionary *A=[NSMutableDictionary dictionary];//Attributes
    for (NSString *key in J)
    {
        if ([J[key] isKindOfClass:[NSDictionary class]]) [A addEntriesFromDictionary:J[key]];
    }
    NSArray *K=nil;
    if (A.count)
    {
        K=[[A allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    uint32 tag;
    uint16 vr;
    uint16 vl;
    uint32 vll;

    for (NSString *key in K)
    {
        vr=[key characterAtIndex:key.length-2]+([key characterAtIndex:key.length-1]*0x100);
        
        tag=(([key characterAtIndex:key.length-11]-0x30)*0x10)
           +(([key characterAtIndex:key.length-10]-0x30)*0x1)
        
           +(([key characterAtIndex:key.length-9 ]-0x30)*0x1000)
           +(([key characterAtIndex:key.length-8 ]-0x30)*0x100)
        
        
           +(([key characterAtIndex:key.length-7 ]-0x30)*0x100000)
           +(([key characterAtIndex:key.length-6 ]-0x30)*0x10000)
        
           +(([key characterAtIndex:key.length-5 ]-0x30)*0x10000000)
           +(([key characterAtIndex:key.length-4 ]-0x30)*0x1000000)
        ;
        
        switch (vr) {
            
#pragma mark AE CS DT LO LT PN SH ST TM
            case 0x4541://AE
            case 0x5343://CS
            case 0x5444://DT
            case 0x4f4c://LO
            case 0x544c://LT
            case 0x4e50://PN
            case 0x4853://SH
            case 0x5453://ST
            case 0x4d54://TM
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                NSString *string=[A[key] componentsJoinedByString:@"\\"];
                BOOL odd=string.length % 2;
                vl=string.length + odd;
                [D appendBytes:&vl length:2];
                [D appendData:[string dataUsingEncoding:NSISOLatin1StringEncoding]];
                if (odd) [D appendBytes:&spacepadding length:1];
                break;
            }
            
            
#pragma mark AS
            case 0x5341://AS 4 chars (one value only)
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&lengthfour length:2];
                [D appendData:[(A[@"key"])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                break;
            }
            
            
#pragma mark DA
            case 0x4144://DA 8 chars (one value only)
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&lengtheight length:2];
                [D appendData:[(A[@"key"])[0] dataUsingEncoding:NSASCIIStringEncoding]];
                break;
            }

#pragma mark UC
            case 0x4355:
            /*
             Unlimited Characters
             */
#pragma mark UR
            case 0x5255:
            /*
             Universal Resource Identifier or Universal Resource Locator (URI/URL)
             */
#pragma mark UT
            case 0x5455:
            /*
             A character string that may contain one or more paragraphs. It may contain the Graphic Character set and the Control Characters, CR, LF, FF, and ESC. It may be padded with trailing spaces, which may be ignored, but leading spaces are considered to be significant. Data Elements with this VR shall not be multi-valued and therefore character code 5CH (the BACKSLASH "\" in ISO-IR 6) may be used.
             */
            {
                [D appendBytes:&tag length:4];
                [D appendBytes:&vr length:2];
                [D appendBytes:&lengthzero length:2];
                
                NSData *data=[(A[@"key"])[0] dataUsingEncoding:NSISOLatin1StringEncoding];
                BOOL odd=data.length % 2;
                vll=(uint32)data.length + odd;
                [D appendBytes:&vll length:4];
                [D appendData:data];
                if (odd) [D appendBytes:&spacepadding length:1];

                break;
            }
            
#pragma mark UI
            case 0x4955:
            {
                break;
            }
            
#pragma mark - SQ
            case 0x5153:
            {
                break;
            }
            
#pragma mark - IQ
            case 0x5149:
            {
                break;
            }
            
#pragma mark - IZ
            case 0x5A49:
            {
                break;
            }
            
#pragma mark - SZ
            case 0x5A53:
            {
                break;
            }
            
#pragma mark - IS DS
            case 0x5344://DS
            case 0x5349://IS
            {
                //variable length (eventually ended with 0x20
                break;
            }
            
            
#pragma mark SL
            case 0x4C53:
            {
                //Signed Long
                break;
            }
            
#pragma mark UL
            case 0x4C55:
            {
                //Unsigned Long
                break;
            }
            
            
#pragma mark SS
            case 0x5353:
            {
                //Signed Short
                break;
            }
            
#pragma mark US
            case 0x5355:
            {
                //Unsigned Short
                break;
            }
            
#pragma mark SV
            case 0x5653:
            {
                //Signed 64-bit Very Long
                break;
            }
            
#pragma mark UV
            case 0x5655:
            {
                //Unsigned 64-bit Very Long
                break;
            }
            
#pragma mark FL
            case 0x4C46:
            {
                //Unsigned Long
                break;
            }
            
#pragma mark FD
            case 0x4446:
            {
                break;
            }
            
#pragma mark OB OD OF OL OV OW UN
            case 0x424F:
            /*
             An octet-stream where the encoding of the contents is specified by the negotiated Transfer Syntax. OB is a VR that is insensitive to byte ordering (see Section 7.3). The octet-stream shall be padded with a single trailing NULL byte value (00H) when necessary to achieve even length.
             */
            case 0x444F:
            /*
             A stream of 64-bit IEEE 754:1985 floating point words. OD is a VR that requires byte swapping within each 64-bit word when changing byte ordering (see Section 7.3).
             */
            case 0x464F:
            /*
             A stream of 32-bit IEEE 754:1985 floating point words. OF is a VR that requires byte swapping within each 32-bit word when changing byte ordering (see Section 7.3).
             */
            case 0x4C4F:
            /*
             A stream of 32-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OL is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x564F:
            /*
             A stream of 64-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OV is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x574F:
            /*
             A stream of 16-bit words where the encoding of the contents is specified by the negotiated Transfer Syntax. OW is a VR that requires byte swapping within each word when changing byte ordering (see Section 7.3).
             */
            case 0x4E55:
            {
                break;
            }
            
            
#pragma mark TODO AT (hexBinary 4 bytes)
            case 0x5441:
            {
                break;
            }
            
            
            default://ERROR unknow VR
            {
#pragma mark ERROR4: unknown VR
                NSLog(@"vr: %d", vr);
                NSLog(@"ERROR4: unknown VR");
                exit(4);
                break;
            }
        }
    }
}
