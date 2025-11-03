exports.handler = async (event) => {
    // Simple video processing function
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Mock video processing
    const response = {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Video processing initiated',
            timestamp: new Date().toISOString(),
            requestId: event.requestContext ? event.requestContext.requestId : 'direct-invocation'
        })
    };
    
    return response;
};