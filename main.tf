provider "aws" {
	region = "eu-central-1"
}

#######Policy for lambda function##########
resource "aws_iam_role" "hello_logs" {
  name               = "hello_logs"
  assume_role_policy = "${data.aws_iam_policy_document.hello_logs.json}"
}

resource "aws_iam_role_policy" "hello_policy_logs" {
  name   = "hello_policy_logs"
  role   = "${aws_iam_role.hello_logs.id}"
  policy = "${data.aws_iam_policy_document.hello_logs_policy.json}"
}

data "aws_iam_policy_document" "hello_logs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "hello_logs_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}
    
########################################
#######Create sns topic##########  

resource "aws_sns_topic" "hello_world_sns_topic" {
  name  = "hello_world_sns_topic"
} 
     
########################################
#######Subscribe lambda to sns topic##########  
 
resource "aws_sns_topic_subscription" "sub_hello_lambda" {
  topic_arn = "${aws_sns_topic.hello_world_sns_topic.arn}"
  protocol  = "lambda"
  endpoint = "${aws_lambda_function.hello_world.arn}"
} 
      
########################################
#######Enable trigger betten sns-lambda##########  
 
resource "aws_lambda_permission" "hello_trigger_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hello_world.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.hello_world_sns_topic.arn}"
}       

########################################
#######Create lambda function##########  
 
resource "aws_lambda_function" "hello_world" {
	function_name = "hello_world"
	handler = "index.handler"
	runtime = "nodejs8.10"
	filename = "function.zip"
	source_code_hash = "${base64sha256(file("function.zip"))}"
	role = "${aws_iam_role.hello_logs.arn}"
}
