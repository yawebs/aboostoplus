<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';
if (isset($_POST['add-bank'])) {
    $ownerId = $_POST['ownerId'];
    $bankName = $_POST['bankName'];
    $accountName = $_POST['accountName'];
    $accountNumber = $_POST['accountNumber'];
    $checkExist = $helper->checkBankExist($ownerId, $bankName, $accountName, $accountNumber);
    if ($checkExist == false) {
        $exec = $helper->addBank($ownerId, $bankName, $accountName, $accountNumber);
        if ($exec == true) {
            $response->status = true;
            $response->message = 'Successful';
        } else {
            $response->status = false;

            $response->message = 'Unable to add items to database';
        }
    } else {
        $response->status = false;

        $response->message = 'Bank Details Already Exist';
    }


    header('Content-type: application/json');
    echo json_encode($response);
} else if (isset($_POST['update-bank']) && isset($_POST['ownerId'])) {
    $ownerId = $_POST['ownerId'];
    $id = $_POST['id'];
    $helper->unsetDefualtBank($ownerId);
    $exec = $helper->updateDefualtBank($ownerId, $id);

    if ($exec == true) {
        $response->status = true;

        $response->message = 'Default Bank successfully updated';
    } else {
        $response->status = false;

        $response->message = 'Unable to upate defualt bank';
    }


    header('Content-type: application/json');
    echo json_encode($response);
} else {
    $response->status = false;

    $response->message = 'Unauthorize request';
    header('Content-type: application/json');
    echo json_encode($response);
}
