<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';
if(isset($_POST['fetch_agent_deal'])){
    $agentId =$_POST['agent_id'];
    $deals = $helper->getAgentDeals($agentId);

    $response->status='Success';
$response->data=$deals;
}else if(isset($_POST['fetch_customer_deal'])){
    $customerId =$_POST['customer_id'];
    $deals = $helper->getCustomerDeals($customerId);

    $response->status='Success';
$response->data=$deals;
}else{
    $response->status = 'unauthorized'; 
}

header('Content-type: application/json');
echo json_encode($response);