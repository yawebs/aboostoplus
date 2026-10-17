<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error='';

$states = $helper->getStates();
$response->status='Success';
$response->data=$states;
header('Content-type: application/json');
echo json_encode($response);