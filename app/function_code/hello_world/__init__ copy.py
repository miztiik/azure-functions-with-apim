import azure.functions as func
import os
import logging

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Oye Python HTTP trigger function processed a request.')
    headers = {"miztiik-automation-processed": "yes"}

    n=None
    b=None
    m=None

    n = req.params.get('name')
    logging.info(f"route_param:{req.route_params}")
    
    logging.info(f"url:{req.url}")
    logging.info(f"headers-------------------0------------------->:{dir(req.headers)}")


    # for k in req.headers.items():
    #     logging.info(f"{k}")
    if not n:
        try:
            req_body = req.get_json()
            b = req_body.get("name")
            logging.info(f"b:{b}")
        except ValueError:
            logging.info(f"No body found. Content Share")
            pass
            
    
    if req.method == "POST":
        m="POST"
    elif req.method == "GET":
        m="GET"

    if n:
        n = f"{n} - From Params"
        return func.HttpResponse(f"Hello {n}, by {m}", headers=headers)
    elif b:
        b = f"{b} - From Body"
        return func.HttpResponse(f"Hello {b}, by {m}", headers=headers)
    else:
        return func.HttpResponse("This HTTP triggered function executed successfully.", 
                                 headers=headers, 
                                 status_code=200
                                 )


