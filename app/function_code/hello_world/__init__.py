import azure.functions as func
import logging

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Oye Python HTTP trigger function processed a request.')

    name = f"{req.params.get('name')} - From Params"
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = 
            name = f"{req_body.get('name')} - From Body"

    if name:
        return func.HttpResponse(f"Hello, {name}.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully.",
             status_code=200
        )


