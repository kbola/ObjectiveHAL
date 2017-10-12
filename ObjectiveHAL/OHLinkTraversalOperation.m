//
//  OHLinkTraversalOperation
//  ObjectiveHAL
//
//  Created by Bennett Smith on 8/26/13.
//  Copyright (c) 2013 ObjectiveHAL. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AFNetworking/AFNetworking.h>

#import "OHLinkTraversalOperation.h"
#import "OHResource.h"

@interface OHLinkTraversalOperation ()
@property (readwrite, strong, nonatomic) NSString *rel;
@property (readwrite, strong, nonatomic) NSString *path;

@property (readwrite, strong, nonatomic) OHResource *resource;
@property (readwrite, strong, nonatomic) OHLinkTraversalHandler traversalHandler;
@property (readwrite, strong, nonatomic) OHCompletionHandler completionHandler;

@property (readwrite, strong, nonatomic) NSOperationQueue *operationQueue;
@property (readwrite, strong, nonatomic) NSArray *embeddedOperations;
@property (readwrite, strong, nonatomic) NSArray *externalOperations;
@property (readwrite, strong, nonatomic) NSArray *nestedOperations;

@property (readwrite, strong, nonatomic) NSMutableArray *resources;

@property (readwrite, strong, nonatomic) AFHTTPSessionManager *sessionManager;
@end

@implementation OHLinkTraversalOperation

- (void)getURL:(NSString*)fullURL withCompletion:(OHCompletionHandler)completion{
    
    if(!fullURL){
        NSError * error = [NSError errorWithDomain:@"com.objectivehal.portal" code:@"101" userInfo:@{@"localizedDescription":@"no href found for operation"}];
        
        completion(nil, error);
    }
    
    NSLog(@"ObjectiveHAL: OHLinkTraversalOperation: getURL: %@", fullURL);
    
    [self.sessionManager GET:fullURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSLog(@"JSON: %@", responseObject);
        OHResource *resource;

        id resourceJSON = responseObject;
        if (resourceJSON) {
             resource = [OHResource resourceWithJSONData:resourceJSON];
        }
        
        completion(resource, nil);
        
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        
        completion(nil, error);
        NSLog(@"Error: %@", error);
    }];
    
}



+ (OHLinkTraversalOperation *)traverseRel:(NSString *)rel inResource:(OHResource *)resource withSessionManager:(AFHTTPSessionManager *)sessionManager completion:(OHCompletionHandler)completion {
    
    OHLinkTraversalOperation *op = [[OHLinkTraversalOperation alloc] init];
    
    op.sessionManager = sessionManager;

    op.rel = rel;
    op.path = nil;
    op.completionHandler = completion;
    op.resource = resource;
    op.resources = [NSMutableArray array];
    
    NSArray *linkedResourceLinks = [op.resource externalLinksForRel:op.rel];
    
    NSString *path;
    
    if([linkedResourceLinks count] > 1){
        NSLog(@"OHLinkTraversal has %i external link for rel %@", linkedResourceLinks.count);
    }
    
    for (OHLink *link in linkedResourceLinks) {
        NSLog(@"OHLinkTraversal following href for rel %@", [link href]);
        path = [link href];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:path];
    

    NSURLQueryItem *limit = [NSURLQueryItem queryItemWithName:@"limit" value:@"100"];
    components.queryItems = [components.queryItems arrayByAddingObjectsFromArray:@[limit]];
    
    [op getURL:components.URL.absoluteString withCompletion:completion];
    
    return op;

}

+ (OHLinkTraversalOperation *)traversePath:(NSString *)path withSessionManager:(AFHTTPSessionManager *)sessionManager completion:(OHCompletionHandler)completion {
    
    OHLinkTraversalOperation *op = [[OHLinkTraversalOperation alloc] init];
    
    op.sessionManager = sessionManager;

    op.path = path;
    op.rel = nil;
    
    op.completionHandler = completion;
    
    op.resource = nil;
    op.resources = [NSMutableArray array];
    
    NSURL * url = [NSURL URLWithString:path relativeToURL:op.sessionManager.baseURL];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];

    NSURLQueryItem *limit = [NSURLQueryItem queryItemWithName:@"limit" value:@"100"];
    components.queryItems = [components.queryItems arrayByAddingObjectsFromArray:@[limit]];

    [op getURL:components.URL.absoluteString withCompletion:completion];
    
    return op;
}


- (void)main {
    //[self processExternalOperations];
    //[self callTraversalHandlers];
}



@end
