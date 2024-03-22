# Point - API Gateway

## Introdução

Este projeto consiste em configurar uma API Gateway na AWS com rotas para diferentes funcionalidades, como autenticação, geração de relatórios e consulta de dados. A API Gateway é configurada para usar o AWS Cognito para autenticação de usuários.

## Arquitetura

A arquitetura do projeto envolve os seguintes componentes:

1. API Gateway: Serviço da AWS que permite criar, publicar, manter, monitorar e proteger APIs em escala.
2. AWS Lambda: Serviço de computação serverless da AWS usado para executar código sem a necessidade de provisionar ou gerenciar servidores.
3. AWS Cognito: Serviço de autenticação e autorização da AWS usado para controlar o acesso à API Gateway.
4. AWS SQS: Serviço de filas de mensagens da AWS usado para processar mensagens assíncronas entre componentes do sistema.

## Fluxo de Trabalho

1. Um cliente faz uma solicitação HTTP para a API Gateway.
2. A API Gateway verifica a autenticação do cliente usando o AWS Cognito.
3. Se a autenticação for bem-sucedida, a API Gateway encaminha a solicitação para a função Lambda correspondente.
4. A função Lambda processa a solicitação e retorna uma resposta à API Gateway.
5. A API Gateway retorna a resposta ao cliente.

## Configuração

Antes de implantar a API Gateway, é necessário configurar os seguintes recursos:

1. AWS Cognito User Pool: Um pool de usuários do AWS Cognito onde os usuários serão autenticados.
2. AWS SQS Queue: Uma fila do AWS SQS para processar mensagens de relatórios.
3. AWS IAM Role: Uma função IAM que permite que a API Gateway acesse os recursos necessários.

## Implantação

A implantação do projeto é realizada da seguinte maneira:

1. Os arquivos de configuração Terraform são preparados com as informações necessárias, como região da AWS e IDs de recursos.
2. Os recursos são criados e implantados na AWS usando o Terraform.
3. A API Gateway é configurada com as rotas e integrações necessárias para cada funcionalidade.

## Recursos

- Terraform: Utilizado para a automação da infraestrutura na AWS.
- AWS API Gateway: Serviço da AWS para criar e gerenciar APIs.
- AWS Lambda: Serviço de computação serverless da AWS.
- AWS Cognito: Serviço de autenticação e autorização da AWS.
- AWS SQS: Serviço de filas de mensagens da AWS.

## Conclusão

Este projeto demonstra como configurar uma API Gateway na AWS para autenticar usuários usando o AWS Cognito e integrar com funções Lambda para processamento de solicitações. Ele oferece uma solução escalável e segura para expor funcionalidades de um aplicativo por meio de uma API RESTful.
