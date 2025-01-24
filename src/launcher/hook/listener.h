#pragma once

#include <gumpp.hpp>

namespace luadebug::autoattach {

    struct common_listener : Gum::NoLeaveInvocationListener {
        virtual ~common_listener() = default;
        virtual void on_enter(Gum::InvocationContext* context) override;
    };

    struct ret_listener : Gum::NoEnterInvocationListener {
        virtual ~ret_listener() = default;
        virtual void on_leave(Gum::InvocationContext* context) override;
    };
}
