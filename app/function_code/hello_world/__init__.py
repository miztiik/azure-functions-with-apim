import azure.functions as func
import os
import logging

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Oye Python HTTP trigger function processed a request.')
    headers = {"miztiik-automation-processed": "yes"}
    return func.HttpResponse("Miztiik Automation Function executed successfully.", 
                                 headers=headers, 
                                 status_code=200
                                 )


