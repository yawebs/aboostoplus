<?php
include '../include/db_con.php';
include '../func/helper.php';

$response = new stdClass;
$response->status = null;
$response->error = '';
$response->data = null;
$helper = new Helper();
if (isset($_POST['auth_user'])) {
    $email = $_POST['email'];

    if ($helper->checkUserExist($email) == true) {
        $response->status = 1;
        $response->error = 'User Exist';
    } else {
        $firsName = $_POST['first_name'];
        $lastName = $_POST['last_name'];
        $password = $_POST['password'];
        $phone = $_POST['phone'];
        $address = $_POST['address'];
        $state = $_POST['state'];
        $city = $_POST['city'];
        $leadUid = $_POST['lead_uid'];
        $profileImage = $_POST['profile_image'];
        $userType = $_POST['user_type'];
        $uniqueId = $_POST['unique_id'];
        $notificationId = $_POST['notification_id'];
        $exec = $helper->createUserAccount($uniqueId, $firsName, $lastName, $email, $password, $phone, $city, $userType, $leadUid, $address, $notificationId, $profileImage, $state);
        if ($exec == true) {
            $response->status = 1;
            $response->error = 'success';
        } else {
            $response->status = 0;
            $response->error = 'Unable to create an account, please try again later';
        }
    }


    header('Content-type: application/json');
    echo json_encode($response);
} else if (isset($_POST['action']) && $_POST['action'] == 'login') {
    // login
    $email = $_POST['email'];
    $password = $_POST['password'];
    $notificationToken = $_POST['notification_token'];
    $isAuth = $helper->loginUser($email, $password, $notificationToken);
    if ($isAuth == true) {
        $user = $helper->getUser($email);
        $response->status = 1;
        $response->error = 'success';
        $response->data = $user;
    } else {
        $response->status = 0;
        $response->error = 'Invalid email or password';
    }
    header('Content-type: application/json');
    echo json_encode($response);
} else if (isset($_POST['get_user']) && $_POST['get_user'] == 'fetch') {
    $queryType = $_POST['type'];
    if ($queryType == 'email') {
        $user = $helper->getUser($_POST['email']);
        $response->status = 1;
        $response->error = 'success';
        $response->data = $user;
        header('Content-type: application/json');
        echo json_encode($response);
    } else if ($queryType == 'id') {
        $user = $helper->getUserById($_POST['id']);
        $response->status = 1;
        $response->error = 'success';
        $response->data = $user;
        header('Content-type: application/json');
        echo json_encode($response);
    }
} else {
    $response->status = 0;
    $response->error = 'Invalid Request';
    header('Content-type: application/json');
    echo json_encode($response);
}
