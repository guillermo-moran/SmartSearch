#import <Foundation/Foundation.h>
#import <SearchLoader/TLLibrary.h>

@interface SmartSearch : NSObject <SPSearchDatastore> { BOOL loading; } @end

@implementation SmartSearch

- (void)performQuery:(SDSearchQuery *)query withResultsPipe:(SDSearchQuery *)results {
    
    TLRequireInternet(YES); //Tell SearchLoader that this plugin requires an internet connection
    loading = YES; //Query is loading results, return "loading" on - (BOOL)blockDatastoreComplete to prevent SearchLoader from stopping your plugin from loading.
    
	NSString *searchString = [query searchString]; //Search field input
	SPSearchResult *result = [[[SPSearchResult alloc] init] autorelease]; //Search result
    
    
    //=====Formats the query into a Google Search Query to load in safari (should the need arise)=====//
    NSString *searchQuery = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* searchURL = [NSString stringWithFormat:@"http://www.google.com/search?q=%@&ie=utf-8&oe=utf-8", searchQuery];
    if (TLIsOS6) [result setUrl:searchURL];
    else [result setURL:[NSURL URLWithString:searchURL]];
    //===============================================================================================//
    
    
    
    //==================================================================================================//
    //==================================================================================================//
    //==================================== ASYNC SERVER REQUEST ========================================//
    //==================================================================================================//
    //==================================================================================================//
    
    NSString* serverURL = @"http://esra.fr0st.me/SmartServer.php";
    
    //OPERATION QUEUE
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    //Setup the request to the server
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3];
    [request setHTTPMethod:@"POST"];
    NSData *requestBody = [[NSString stringWithFormat:@"request=%@",searchString] dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBody];
    
    //==================================================================================================//
    //==================================== NSURL CONNECTION HANDLERS ===================================//
    //==================================================================================================//
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (data != nil) {
         
            //Retreive the string and parse it into two lines (seperates by a "/"
            
            NSString* resultString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"***SMARTSEARCH*** Server response: %@", resultString);
            NSArray *splitString = [resultString componentsSeparatedByString:@"/"];
            NSString* titleStr = [NSString stringWithFormat:@"%@",[splitString objectAtIndex:0]];
            NSString* subtitleStr = [NSString stringWithFormat: @"%@",[splitString objectAtIndex:1]];
            
            if ([subtitleStr hasPrefix:@" "]) {
                //This is lazy, Don't try this at home!
                subtitleStr = @"Tap For More Information.";
            }
            
            //Set the cell's Title and Subtitle/Summary String
            [result setTitle:titleStr];
            [result setSummary:subtitleStr];
            
            NSLog(@"****SERVER RESULT**** %@",resultString);
            
            //Commit the results to Spotlight
            TLCommitResults([NSArray arrayWithObject:result], TLDomain(@"com.apple.mobilesafari", @"SmartSearch"), results);

        }
        else {
            //If no response from server is found, tell the user
            
            [result setTitle:@"SmartServer Connection Error"];
            [result setSummary:@"Search in Google"];
            TLCommitResults([NSArray arrayWithObject:result], TLDomain(@"com.apple.mobilesafari", @"SmartSearch"), results);
        }
        
        //Cleanup
        loading = NO; //Tell spotlight it's okay to stop loading
        TLRequireInternet(NO); //Tell spotlight you're no longer using the internet
        TLFinishQuery(results); //Tell spotlight you're done with the query
        
        [results storeCompletedSearch:self]; //Completed search
        if (!TLIsOS6) [results queryFinishedWithError:nil]; //Completed search
        
    }];
    

    
}

- (NSArray *)searchDomains {
	return [NSArray arrayWithObject:[NSNumber numberWithInteger:TLDomain(@"com.apple.mobilesafari", @"SmartSearch")]];
}

- (NSString *)displayIdentifierForDomain:(NSInteger)domain {
	return @"com.apple.mobilesafari";
}

- (BOOL)blockDatastoreComplete {
   
    /*
     This BOOL tells spotlight whether or not it can complete the search query.
     
     YES = Continue to load
      NO = Stop loading and finish
    */
    
    return loading;
}
@end
