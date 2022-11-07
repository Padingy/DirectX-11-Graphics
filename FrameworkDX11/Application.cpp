//#include "main.h"
//
//int WINAPI wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPWSTR lpCmdLine, _In_ int nCmdShow)
//{
//    UNREFERENCED_PARAMETER(hPrevInstance);
//    UNREFERENCED_PARAMETER(lpCmdLine);
//
//    Application* application = new Application();
//
//    if (FAILED(application->InitWindow(hInstance, nCmdShow)))
//        return 0;
//
//    if (FAILED(application->InitDevice()))
//    {
//        application->CleanupDevice();
//        return 0;
//    }
//
//    // Main message loop
//    MSG msg = { 0 };
//    while (WM_QUIT != msg.message)
//    {
//        if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE))
//        {
//            TranslateMessage(&msg);
//            DispatchMessage(&msg);
//        }
//        else
//        {
//            application->Render();
//        }
//    }
//
//    application->CleanupDevice();
//
//    return (int)msg.wParam;
//}