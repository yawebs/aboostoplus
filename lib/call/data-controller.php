<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';
$fullName = $_POST['fullName'];
$phone = $_POST['phone'];
$address = $_POST['address'];
$schName = $_POST['schName'];
$department = $_POST['department'];
$schAddress = $_POST['schAddress'];
$userType = $_POST['userType'];
$uState = $_POST['uState'];
$uCity = $_POST['uCity'];
$uState = $_POST['uState'];
$email = $_POST['email'];
$pwd = $_POST['pwd'];
$uniqId = $_POST['uniqId'];

$checkExist = $helper->checkEmailExist($email);
if ($checkExist == 1) {
    $response->status = false;

    $response->message = 'User with this account already exist, please try login in';
} else {
    $hashedPassword = password_hash($pwd, PASSWORD_DEFAULT);
    $exec = $helper->addUser($uniqId, $fullName, $phone, $address, $schName, $email, $department, $schAddress, $userType, $uState, $uCity, $hashedPassword);
    if ($exec == true) {
        $response->status = true;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable to add items to database';
    }
}


header('Content-type: application/json');
echo json_encode($response);
