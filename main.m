//
//  main.m
//  cda2mwl
//
//  Created by jacquesfauquex@opendicom.com on 2014-07-30.
//  Copyright (c) 2014-2021 opendicom.com. All rights reserved.

#import <Foundation/Foundation.h>
#import "ZZArchiveEntry.h"
#import "ZZArchive.h"
#import "ZZConstants.h"
#import "ZZChannel.h"
#import "ZZError.h"

#import "ODLog.h"

#import "NSTask+function.h"

#import "JD.h"

int main(int argc, const char * argv[])
{
 @autoreleasepool {
     
     
#pragma mark init
     
    NSError *err=nil;
    const uint64 tag00420011=0x0000424F00110042;//encapsulatedCDA tag + vr + padding (used in order to find the offset)
    NSFileManager *fileManager=[NSFileManager defaultManager];

    //http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    NSDateFormatter *DAFormatter = [[NSDateFormatter alloc] init];
    [DAFormatter setDateFormat:@"yyyyMMdd"];

#pragma mark args
     
     NSMutableArray *args=[NSMutableArray arrayWithArray:[[NSProcessInfo processInfo] arguments]];
     //NSLog(@"%@",[args description]);
     //[0] command path
     //[1] xslt1 path
     //[2] qido base url
     //[3] audit folder
     
     
     
     //[1]cda2mwl.xsl path
     NSData *xslt1Data=[NSData dataWithContentsOfFile:[args[1] stringByExpandingTildeInPath]];
     
    //NSString *DA=@"20161018";
    NSString *DA=[DAFormatter stringFromDate:[NSDate date]];
     
     //arg[2] base URL
     //ejemplo: https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE/instances?Modality=OT&SeriesDescription=solicitud&NumberOfStudyRelatedInstances=1&00080080=asseMALDONADO&StudyDate=20210128&StudyTime=1210-
     NSURL *qidoURL=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",args[2],DA]];
     
     //arg[3] audit path
     NSString *todayAuditPath=[[args[3] stringByExpandingTildeInPath] stringByAppendingPathComponent:DA];
     
     
#pragma mark qido
     NSData *qidoResponse=[NSData dataWithContentsOfURL:qidoURL
                                                options:NSDataReadingUncached
                                                  error:&err];
     if (err)
     {
        LOG_ERROR(@"%@",[err description]);
        exit(0)
     }
     if (!qidoResponse)
     {
        LOG_WARNING(@"no answer to qido");
        exit(0)
     }
     if (![qidoResponse length]) exit(0);


      NSArray *list = [NSJSONSerialization JSONObjectWithData:qidoResponse options:0 error:&err];
      //NSLog(@"%@",[list description]);
      for (NSDictionary *instance in list)
      {
#pragma mark loop for each solicitud
          NSDictionary *now = [NSDictionary dictionaryWithObject:DA forKey:@"now"];
          
          NSString *PatientID=[[[instance objectForKey:@"00100020"]objectForKey:@"Value"]firstObject];
          NSString *StudyInstanceUID=[[[instance objectForKey:@"0020000D"]objectForKey:@"Value"]firstObject];
          NSURL *RetrieveURL=[NSURL URLWithString:[[[instance objectForKey:@"00081190"]objectForKey:@"Value"]firstObject]];//RetrieveURL
          NSString *sopAuditPath=[[todayAuditPath stringByAppendingPathComponent:PatientID] stringByAppendingPathComponent:StudyInstanceUID];

         
          //if already downloaded
          if([fileManager fileExistsAtPath:sopAuditPath])continue;

         
          
          LOG_INFO(@"wado-rs solicitud: %@",sopAuditPath);
          if(![fileManager createDirectoryAtPath:sopAuditPath withIntermediateDirectories:YES attributes:nil error:nil])
          {
             LOG_ERROR(@"ERROR could not create folder");
             continue;
          }
         
         
          NSData *downloaded=[NSData dataWithContentsOfURL:RetrieveURL];
           if (!downloaded)
          {
            LOG_WARNING(@"no answer to downloaded");
            continue;
          }
          if (![qidoResponse length]) exit(0);
          
          //unzip
          NSError *error=nil;
          ZZArchive *archive = [ZZArchive archiveWithData:downloaded];
          ZZArchiveEntry *firstEntry = archive.entries[0];
          NSData *unzipped = [firstEntry newDataWithError:&error];
          if (error!=nil)
          {
             LOG_WARNING(@"ERROR could NOT unzip");
             [downloaded writeToFile:[sopAuditPath stringByAppendingPathComponent:@"unzippeable.zip"] atomically:NO];
             continue;
          }
         
          //get CDA: 00420011
          NSRange range00420011=[unzipped rangeOfData:[NSData dataWithBytes:(void*)&tag00420011 length:8]
                                               options:0
                                                 range:NSMakeRange(0,[unzipped length])];
          if (range00420011.location==NSNotFound)
          {
              LOG_WARNING(@"no contiene attr 00420011");
             [unzipped writeToFile:[sopAuditPath stringByAppendingPathComponent:@"noTag00420011.xml"] atomically:NO];
              continue;
          }
          //get CDA: 00420011.length
          uint32 capsuleLength=0x00000000;
          [unzipped getBytes:&capsuleLength range:NSMakeRange(range00420011.location+8,4)];
            
          unsigned char padded=0xFF;
          [unzipped getBytes:&padded range:NSMakeRange(range00420011.location+12+capsuleLength-1,1)];
          NSData *encapsulatedData=[[NSData alloc]initWithData:[unzipped subdataWithRange:NSMakeRange(range00420011.location+12,capsuleLength-(padded==0))]];
            
          if (!encapsulatedData)
          {
            LOG_WARNING(@"attr 00420011 empty");
            continue;
          }

          NSXMLDocument *xmlDocument = [[NSXMLDocument alloc]initWithData:encapsulatedData options:0 error:&error];
          if (!xmlDocument)
          {
             LOG_WARNING(@"00420011 not xml\r%@",[error description]);
             [encapsulatedData writeToFile:[sopAuditPath stringByAppendingPathComponent:@"00420011bad.xml"] atomically:NO];
             continue;
          }

          [[xmlDocument XMLData] writeToFile:[sopAuditPath stringByAppendingPathComponent:@"solicitud.xml"] atomically:NO];
                 
          //transform CDA 2 json contextualkey-values
             
          //serialize it to dicom
             
          id mwlitemjson = [xmlDocument objectByApplyingXSLT:xslt1Data
                                                   arguments:now
                                                       error:&error];
          if (!mwlitemjson)
          {
             LOG_WARNING(@"could not transform the CDA solicitud to wlijson\r%@",[error description]);
             continue;
          }
         
          if (![mwlitemjson isKindOfClass:[NSData class]])
          {
             LOG_WARNING(@"ERROR xslt1 cda2mwl didn´t output data file");
             continue;
          }

         //serialize it to dicom
         NSDictionary *json=[NSJSONSerialization JSONObjectWithData:mwlitemjson options:0 error:&error];
         if (!json)
         {
            LOG_WARNING(@"ERROR reading json: %@",[error description]);
            continue;
         }
         NSMutableData *dicom=[NSMutableData data];
         JD(json, dicom);
         
         //copy to folder DCM4CHEE
       }
    }
 }
 return 0;
}
